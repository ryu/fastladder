# frozen_string_literal: true

require "feedjira"
require "nokogiri"
require "addressable/uri"

module Fastladder
  # FeedParser handles parsing of RSS/Atom feeds with format normalization.
  #
  # This class separates parsing concerns from crawler business logic:
  # - Parses RSS 1.0, RSS 2.0, and Atom feeds via Feedjira
  # - Normalizes data across different feed formats
  # - Fixes relative URLs in content
  # - Returns structured data independent of ActiveRecord
  #
  # @example Basic usage
  #   parser = Fastladder::FeedParser.new
  #   result = parser.parse(xml_content, base_url: "https://example.com/feed.xml")
  #   if result.success?
  #     result.feed_info  # => { title: "...", link: "...", description: "..." }
  #     result.items      # => Array of ParsedItem
  #   else
  #     handle_error(result.error)
  #   end
  #
  class FeedParser
    attr_reader :logger

    def initialize(logger: nil)
      @logger = logger
    end

    # Parse feed content and return normalized result.
    #
    # @param content [String] Raw feed content (XML/RSS/Atom)
    # @param base_url [String, nil] Base URL for resolving relative links
    # @return [ParseResult] The result of the parse operation
    def parse(content, base_url: nil)
      return ParseResult.error("Empty content") if content.nil? || content.strip.empty?

      begin
        parsed = Feedjira.parse(content)
        return ParseResult.error("Failed to parse feed") unless parsed

        feed_info = extract_feed_info(parsed)
        items = build_items(parsed.entries, base_url: base_url)

        ParseResult.success(feed_info: feed_info, items: items)

      rescue Feedjira::NoParserAvailable => e
        log_warn("No parser available: #{e.message}")
        ParseResult.error("Unsupported feed format")

      rescue StandardError => e
        log_error("Parse error: #{e.class} - #{e.message}")
        ParseResult.error("Parse error: #{e.message}")
      end
    end

    private

    def extract_feed_info(parsed)
      {
        title: normalize_text(parsed.title),
        link: parsed.url,
        description: normalize_text(parsed.description)
      }
    end

    def build_items(entries, base_url:)
      entries.map do |entry|
        build_item(entry, base_url: base_url)
      end
    end

    def build_item(entry, base_url:)
      body = entry.content || entry.summary
      body = fixup_relative_links(body, base_url: base_url) if body && base_url

      ParsedItem.new(
        guid: entry.id,
        link: entry.url || "",
        title: normalize_text(entry.title) || "",
        body: body,
        author: normalize_text(entry.author),
        category: extract_category(entry),
        published_at: normalize_datetime(entry.published),
        enclosure: extract_enclosure(entry),
        enclosure_type: extract_enclosure_type(entry)
      )
    end

    def normalize_text(text)
      return nil if text.nil?
      text.to_s.strip.presence
    end

    def normalize_datetime(value)
      return nil if value.nil?
      value.to_datetime
    rescue StandardError
      nil
    end

    def extract_category(entry)
      categories = entry.try(:categories)
      return nil unless categories.is_a?(Array) && categories.any?
      categories.first
    end

    def extract_enclosure(entry)
      entry.try(:enclosure_url)
    end

    def extract_enclosure_type(entry)
      entry.try(:enclosure_type)
    end

    def fixup_relative_links(body, base_url:)
      return body if body.nil? || body.empty?

      doc = Nokogiri::HTML.fragment(body)

      # Fix anchor hrefs
      doc.css("a[href]").each do |link|
        link["href"] = resolve_url(link["href"], base_url: base_url)
      end

      # Fix image srcs
      doc.css("img[src]").each do |img|
        img["src"] = resolve_url(img["src"], base_url: base_url)
      end

      doc.to_html
    end

    def resolve_url(url, base_url:)
      return url if url.nil? || url.empty?
      return url if url.start_with?("data:") # Data URIs

      Addressable::URI.join(base_url, url).normalize.to_s
    rescue Addressable::URI::InvalidURIError => e
      log_debug("Invalid URL: #{url} (base: #{base_url}) - #{e.message}")
      url # Return original if resolution fails
    end

    def log_debug(message)
      logger&.debug("[FeedParser] #{message}")
    end

    def log_warn(message)
      logger&.warn("[FeedParser] #{message}")
    end

    def log_error(message)
      logger&.error("[FeedParser] #{message}")
    end
  end

  # ParseResult encapsulates the result of a feed parse operation.
  #
  class ParseResult
    attr_reader :feed_info, :items, :error

    def initialize(feed_info: nil, items: nil, error: nil)
      @feed_info = feed_info
      @items = items || []
      @error = error
    end

    def self.success(feed_info:, items:)
      new(feed_info: feed_info, items: items)
    end

    def self.error(message)
      new(error: message)
    end

    def success?
      @error.nil?
    end

    def error?
      !success?
    end

    def item_count
      @items.size
    end
  end

  # ParsedItem represents a normalized feed item independent of ActiveRecord.
  #
  # This provides a clean data structure that can be converted to an Item model
  # by the persist layer.
  #
  class ParsedItem
    attr_reader :guid, :link, :title, :body, :author, :category,
                :published_at, :enclosure, :enclosure_type

    def initialize(guid:, link:, title:, body:, author:, category:,
                   published_at:, enclosure: nil, enclosure_type: nil)
      @guid = guid
      @link = link
      @title = title
      @body = body
      @author = author
      @category = category
      @published_at = published_at
      @enclosure = enclosure
      @enclosure_type = enclosure_type
    end

    # Convert to a hash suitable for creating an Item model.
    #
    # @param feed_id [Integer] The feed ID to associate with
    # @return [Hash] Attributes for Item.new
    def to_item_attributes(feed_id:)
      {
        feed_id: feed_id,
        guid: guid,
        link: link,
        title: title,
        body: body,
        author: author,
        category: category,
        enclosure: enclosure,
        enclosure_type: enclosure_type,
        stored_on: Time.current,
        modified_on: published_at
      }
    end

    def to_h
      {
        guid: guid,
        link: link,
        title: title,
        body: body,
        author: author,
        category: category,
        published_at: published_at,
        enclosure: enclosure,
        enclosure_type: enclosure_type
      }
    end
  end
end
