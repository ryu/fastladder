# frozen_string_literal: true

require "json"

module Fastladder
  # CrawlerReporter handles logging and metrics collection for the crawler.
  #
  # This class separates reporting concerns from crawler business logic:
  # - Structured logging with consistent format and context
  # - Metrics collection (success/failure counts, timing, items processed)
  # - Event categorization for monitoring and debugging
  #
  # @example Basic usage
  #   reporter = Fastladder::CrawlerReporter.new(logger: Rails.logger)
  #   reporter.crawl_started(feed)
  #   # ... perform crawl ...
  #   reporter.crawl_completed(feed, result)
  #   puts reporter.summary
  #
  class CrawlerReporter
    # Error categories for classification
    ERROR_TRANSIENT = :transient   # Temporary errors (network, 5xx, rate limit)
    ERROR_PERMANENT = :permanent   # Permanent errors (4xx, parse failure)
    ERROR_UNKNOWN = :unknown       # Unclassified errors

    attr_reader :logger, :metrics

    def initialize(logger: nil, structured: false)
      @logger = logger
      @structured = structured
      @metrics = Metrics.new
      @start_time = Time.zone.now
    end

    # === Crawl Lifecycle Events ===

    def crawl_started(feed)
      @metrics.increment(:crawls_started)
      log_info("crawl_started", feed_id: feed.id, feedlink: feed.feedlink)
    end

    def crawl_completed(feed, result)
      @metrics.increment(:crawls_completed)
      @metrics.add(:items_new, result[:new_items] || 0)
      @metrics.add(:items_updated, result[:updated_items] || 0)

      log_info("crawl_completed",
               feed_id: feed.id,
               feedlink: feed.feedlink,
               new_items: result[:new_items],
               updated_items: result[:updated_items],
               message: result[:message])
    end

    def crawl_failed(feed, error, category: nil)
      @metrics.increment(:crawls_failed)
      category ||= classify_error(error)
      @metrics.increment(:"errors_#{category}")

      log_error("crawl_failed",
                feed_id: feed.id,
                feedlink: feed.feedlink,
                error_class: error.is_a?(Exception) ? error.class.name : "String",
                error_message: error.is_a?(Exception) ? error.message : error.to_s,
                error_category: category)
    end

    def crawl_skipped(feed, reason)
      @metrics.increment(:crawls_skipped)

      log_info("crawl_skipped",
               feed_id: feed.id,
               feedlink: feed.feedlink,
               reason: reason)
    end

    # === Fetch Events ===

    def fetch_started(url)
      log_debug("fetch_started", url: url)
    end

    def fetch_completed(url, result)
      if result.success?
        @metrics.increment(:fetches_success)
        log_info("fetch_completed",
                 url: url,
                 status: result.status_code,
                 attempts: result.attempts)
      elsif result.not_modified?
        @metrics.increment(:fetches_not_modified)
        log_info("fetch_not_modified", url: url)
      elsif result.redirect?
        @metrics.increment(:fetches_redirect)
        log_info("fetch_redirect",
                 url: url,
                 status: result.status_code,
                 redirect_url: result.redirect_url)
      else
        @metrics.increment(:fetches_failed)
        log_warn("fetch_failed",
                 url: url,
                 status: result.status_code,
                 error: result.error_message,
                 attempts: result.attempts,
                 retries_exhausted: result.retries_exhausted?)
      end
    end

    # === Parse Events ===

    def parse_completed(feedlink, result)
      if result.success?
        @metrics.increment(:parses_success)
        @metrics.add(:items_parsed, result.item_count)
        log_info("parse_completed",
                 feedlink: feedlink,
                 item_count: result.item_count)
      else
        @metrics.increment(:parses_failed)
        log_warn("parse_failed",
                 feedlink: feedlink,
                 error: result.error)
      end
    end

    # === Item Events ===

    def items_persisted(feed, new_count, updated_count)
      log_info("items_persisted",
               feed_id: feed.id,
               feedlink: feed.feedlink,
               new_items: new_count,
               updated_items: updated_count)
    end

    def items_deleted(feed, count, reason: nil)
      @metrics.add(:items_deleted, count)

      log_warn("items_deleted",
               feed_id: feed.id,
               feedlink: feed.feedlink,
               count: count,
               reason: reason)
    end

    def items_truncated(feed, original_count, limit)
      log_warn("items_truncated",
               feed_id: feed.id,
               feedlink: feed.feedlink,
               original_count: original_count,
               limit: limit)
    end

    # === System Events ===

    def crawler_started
      @start_time = Time.zone.now
      @metrics.reset
      log_info("crawler_started", time: @start_time.iso8601)
    end

    def crawler_stopped(reason: nil)
      elapsed = Time.zone.now - @start_time
      log_info("crawler_stopped",
               reason: reason,
               elapsed_seconds: elapsed.round(2),
               metrics: @metrics.to_h)
    end

    def crawler_error(error)
      @metrics.increment(:system_errors)
      log_error("crawler_error",
                error_class: error.class.name,
                error_message: error.message,
                backtrace: error.backtrace&.first(5))
    end

    def crawler_idle(interval)
      log_debug("crawler_idle", sleep_seconds: interval)
    end

    # === Metrics Summary ===

    def summary
      elapsed = Time.zone.now - @start_time
      {
        elapsed_seconds: elapsed.round(2),
        **@metrics.to_h
      }
    end

    def summary_line
      m = @metrics
      "Crawls: #{m[:crawls_completed]}/#{m[:crawls_started]} completed, " \
        "#{m[:crawls_failed]} failed | " \
        "Items: #{m[:items_new]} new, #{m[:items_updated]} updated | " \
        "Errors: #{m[:errors_transient]} transient, #{m[:errors_permanent]} permanent"
    end

    private

    def classify_error(error)
      case error
      when Timeout::Error, Errno::ECONNRESET, Errno::ECONNREFUSED,
           Net::OpenTimeout, Net::ReadTimeout, SocketError
        ERROR_TRANSIENT
      when FetchResult
        if error.retries_exhausted? || error.server_error?
          ERROR_TRANSIENT
        elsif error.client_error?
          ERROR_PERMANENT
        else
          ERROR_UNKNOWN
        end
      when String
        if error.include?("parse") || error.include?("format")
          ERROR_PERMANENT
        else
          ERROR_UNKNOWN
        end
      else
        ERROR_UNKNOWN
      end
    end

    def log_debug(event, **context)
      log(:debug, event, context)
    end

    def log_info(event, **context)
      log(:info, event, context)
    end

    def log_warn(event, **context)
      log(:warn, event, context)
    end

    def log_error(event, **context)
      log(:error, event, context)
    end

    def log(level, event, context)
      return unless logger

      if @structured
        # JSON structured logging for production/monitoring
        logger.send(level, format_structured(event, context))
      else
        # Human-readable logging for development
        logger.send(level, format_human(event, context))
      end
    end

    def format_structured(event, context)
      {
        event: event,
        timestamp: Time.now.iso8601,
        **context
      }.to_json
    end

    def format_human(event, context)
      parts = ["[Crawler] #{event}"]
      context.each do |key, value|
        next if value.nil?

        parts << "#{key}=#{value.inspect}"
      end
      parts.join(" ")
    end
  end

  # Metrics collects and aggregates crawler statistics.
  #
  class Metrics
    COUNTERS = %i[
      crawls_started
      crawls_completed
      crawls_failed
      crawls_skipped
      fetches_success
      fetches_failed
      fetches_not_modified
      fetches_redirect
      parses_success
      parses_failed
      errors_transient
      errors_permanent
      errors_unknown
      system_errors
    ].freeze

    SUMS = %i[
      items_new
      items_updated
      items_parsed
      items_deleted
    ].freeze

    def initialize
      reset
    end

    def reset
      @counters = Hash.new(0)
      @sums = Hash.new(0)
    end

    def increment(name, by: 1)
      @counters[name] += by
    end

    def add(name, value)
      @sums[name] += value
    end

    def [](name)
      if COUNTERS.include?(name)
        @counters[name]
      elsif SUMS.include?(name)
        @sums[name]
      else
        @counters[name] || @sums[name] || 0
      end
    end

    def to_h
      result = {}
      COUNTERS.each { |name| result[name] = @counters[name] }
      SUMS.each { |name| result[name] = @sums[name] }
      result
    end
  end
end
