require "fastladder"
require "tempfile"
require "logger"
require "timeout"
begin
  require "image_utils"
rescue LoadError
end

class Crawler
end

module Fastladder
  class Crawler
    ITEMS_LIMIT = 500
    REDIRECT_LIMIT = 5
    CRAWL_OK = 1
    CRAWL_NOW = 10
    GETA = [12_307].pack("U")

    attr_reader :fetcher, :parser, :reporter

    def self.start(options = {})
      logger = options[:logger]

      unless logger
        target = options[:log_file] || STDOUT
        logger = Logger.new(target)
        logger.level = options[:log_level] || Logger::INFO
      end

      logger.warn '=> Booting FeedFetcher...'
      new(logger,
          fetcher: options[:fetcher],
          parser: options[:parser],
          reporter: options[:reporter]).run
    end

    def initialize(logger, fetcher: nil, parser: nil, reporter: nil)
      @logger = logger
      @fetcher = fetcher || build_default_fetcher
      @parser = parser || build_default_parser
      @reporter = reporter || build_default_reporter
    end

    def run
      reporter.crawler_started
      @interval = 0
      finish = false
      finish = run_loop until finish
      reporter.crawler_stopped(reason: "normal")
    end

    def crawl(feed)
      reporter.crawl_started(feed)

      result = {
        message: '',
        error: false,
        response_code: nil
      }

      current_url = feed.feedlink
      modified_since = feed.modified_on

      REDIRECT_LIMIT.times do
        reporter.fetch_started(current_url)
        fetch_result = fetcher.fetch(current_url, modified_since: modified_since)
        reporter.fetch_completed(current_url, fetch_result)

        if fetch_result.not_modified?
          result[:response_code] = fetch_result.status_code
          result[:message] = "Not modified"
          reporter.crawl_skipped(feed, "not_modified")
          break

        elsif fetch_result.success?
          ret = update(feed, fetch_result.response)
          result[:message] = "#{ret[:new_items]} new items, #{ret[:updated_items]} updated items"
          result[:response_code] = fetch_result.status_code
          reporter.crawl_completed(feed, result.merge(new_items: ret[:new_items], updated_items: ret[:updated_items]))
          break

        elsif fetch_result.redirect?
          redirect_url = fetch_result.redirect_url
          feed.feedlink = redirect_url
          feed.modified_on = nil
          feed.save
          current_url = redirect_url
          modified_since = nil

        elsif fetch_result.error?
          result[:message] = "Error: #{fetch_result.error_message}"
          result[:error] = true
          result[:response_code] = fetch_result.status_code
          reporter.crawl_failed(feed, fetch_result.error_message)
          break

        else
          # Unknown response type
          result[:message] = "Error: Unknown response #{fetch_result.status_code}"
          result[:error] = true
          result[:response_code] = fetch_result.status_code
          reporter.crawl_failed(feed, result[:message])
          break
        end
      end

      result
    end

    private

    def build_default_fetcher
      Fastladder::Fetcher.new(
        logger: @logger,
        max_retries: 2,
        rate_limit_delay: 0.5,
        open_timeout: Fastladder.http_open_timeout,
        read_timeout: Fastladder.http_read_timeout
      )
    end

    def build_default_parser
      Fastladder::FeedParser.new(logger: @logger)
    end

    def build_default_reporter
      Fastladder::CrawlerReporter.new(logger: @logger)
    end

    def run_loop
      begin
        run_body
      rescue SignalException => e
        reporter.crawler_stopped(reason: "signal: #{e.message}")
        return true
      rescue Exception => e
        reporter.crawler_error(e)
      ensure
        if @crawl_status
          @crawl_status.status = CRAWL_OK
          @crawl_status.save
        end
      end
      false
    end

    def run_body
      reporter.crawler_idle(@interval) if @interval > 0
      sleep @interval
      if feed = CrawlStatus.fetch_crawlable_feed
        @interval = 0
        result = crawl(feed)
        unless result[:error]
          @crawl_status = feed.crawl_status
          @crawl_status.http_status = result[:response_code]
        end
      else
        @interval = @interval > 60 ? 60 : @interval + 1
      end
    end

    def update(feed, source)
      result = {
        new_items: 0,
        updated_items: 0,
        error: nil
      }

      parse_result = parser.parse(source.body, base_url: feed.feedlink)
      reporter.parse_completed(feed.feedlink, parse_result)

      unless parse_result.success?
        result[:error] = parse_result.error
        return result
      end

      items = build_items_from_parsed(feed, parse_result.items)
      original_count = items.size
      items = cut_off(feed, items)
      reporter.items_truncated(feed, original_count, ITEMS_LIMIT) if items.size < original_count
      items = reject_duplicated(feed, items)

      Feed.transaction do
        delete_old_items_if_new_items_are_many(feed, items)
        update_or_insert_items_to_feed(feed, items, result)
        update_unread_status(feed, result)
        update_feed_information(feed, parse_result.feed_info)
        feed.save!
      end

      reporter.items_persisted(feed, result[:new_items], result[:updated_items])
      feed.fetch_favicon!
      GC.start

      result
    end

    def build_items_from_parsed(feed, parsed_items)
      parsed_items.map do |parsed_item|
        new_item = Item.new(parsed_item.to_item_attributes(feed_id: feed.id))
        new_item.create_digest
        new_item
      end
    end

    def cut_off(_feed, items)
      return items unless items.size > ITEMS_LIMIT

      items[0, ITEMS_LIMIT]
    end

    def reject_duplicated(feed, items)
      items.uniq { |item| item.guid }.reject { |item| feed.items.exists?(["guid = ? and digest = ?", item.guid, item.digest]) }
    end

    def new_items_count(feed, items)
      items.reject { |item| feed.items.exists?(["link = ? and digest = ?", item.link, item.digest]) }.size
    end

    def delete_old_items_if_new_items_are_many(feed, items)
      new_items_size = new_items_count(feed, items)
      return unless new_items_size > ITEMS_LIMIT / 2

      deleted_count = feed.items.count
      Item.where(feed_id: feed.id).delete_all
      reporter.items_deleted(feed, deleted_count, reason: "too_many_new_items")
    end

    # Insert or update items to feed with idempotent handling.
    #
    # Uses find_or_initialize_by pattern and handles uniqueness violations
    # gracefully for concurrent crawler scenarios.
    #
    def update_or_insert_items_to_feed(feed, items, result)
      items.reverse_each do |item|
        upsert_item(feed, item, result)
      end
    end

    def upsert_item(feed, item, result)
      old_item = feed.items.find_by(guid: item.guid)

      if old_item
        # Update existing item
        old_item.increment(:version)
        unless almost_same(old_item.title, item.title) && almost_same((old_item.body || "").html2text, (item.body || "").html2text)
          old_item.stored_on = item.stored_on
          result[:updated_items] += 1
        end
        update_columns = %w[link title body author category enclosure enclosure_type digest modified_on]
        old_item.attributes = item.attributes.select { |column, _value| update_columns.include?(column) }
        old_item.save!
      else
        # Insert new item, handling potential race condition
        begin
          feed.items << item
          result[:new_items] += 1
        rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
          # Another process inserted the same item - retry as update
          raise unless e.is_a?(ActiveRecord::RecordNotUnique) || e.message.include?("guid")

          old_item = feed.items.find_by(guid: item.guid)
          raise unless old_item

          # Retry as update
          upsert_item(feed, item, result)

          # Different uniqueness violation (e.g., link), re-raise
        end
      end
    end

    def update_unread_status(feed, result)
      return unless result[:updated_items] + result[:new_items] > 0

      last_item = feed.items.recent.first
      feed.modified_on = last_item.created_on

      Subscription.where(feed_id: feed.id).update_all(has_unread: true)
    end

    def update_feed_information(feed, feed_info)
      feed.title = feed_info[:title] if feed_info[:title].present?
      feed.link = feed_info[:link] if feed_info[:link].present?
      feed.description = feed_info[:description] || ""
    end

    def almost_same(str1, str2)
      return true if str1 == str2

      chars1 = str1.split('')
      chars2 = str2.split('')
      return false if chars1.length != chars2.length

      # count differences
      [chars1, chars2].transpose.find_all do |pair|
        !pair.include?(GETA) and pair[0] != pair[1]
      end.size <= 5
    end
  end
end
