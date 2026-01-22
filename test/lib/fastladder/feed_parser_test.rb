# frozen_string_literal: true

require "test_helper"

class Fastladder::FeedParserTest < ActiveSupport::TestCase
  def setup
    @parser = Fastladder::FeedParser.new(logger: Rails.logger)
  end

  # === Basic Parsing ===

  test "parses RSS 2.0 feed successfully" do
    content = Rails.root.join("test/fixtures/examlpe.com.feed.xml").read

    result = @parser.parse(content, base_url: "http://example.com/feed.xml")

    assert_predicate result, :success?
    assert_equal 3, result.item_count

    # Check feed info
    assert_equal "熊に関する最新ニュース", result.feed_info[:title]
    assert_equal "http://example.com/feed.xml", result.feed_info[:link]
    assert_includes result.feed_info[:description], "熊に関する架空の最新ニュース"

    # Check first item
    first_item = result.items.first

    assert_equal "北海道で熊がハイキングコースを散策", first_item.title
    assert_equal "http://example.com/bearnews/1", first_item.link
    assert_includes first_item.body, "ツキノワグマ"
  end

  test "parses Atom feed successfully" do
    content = Rails.root.join("test/fixtures/github.private.atom").read

    result = @parser.parse(content, base_url: "https://github.com/eagletmt.private.atom")

    assert_predicate result, :success?
    assert_equal 1, result.item_count

    # Check feed info
    assert_equal "Private Feed for eagletmt", result.feed_info[:title]
    assert_equal "https://github.com/eagletmt", result.feed_info[:link]

    # Check item
    item = result.items.first

    assert_equal "tag:github.com,2008:PushEvent/2666926662", item.guid
    assert_includes item.title, "indirect pushed to 1-9-stable"
    assert_equal "indirect", item.author
  end

  # === Error Handling ===

  test "returns error for empty content" do
    result = @parser.parse("")

    assert_predicate result, :error?
    assert_equal "Empty content", result.error
  end

  test "returns error for nil content" do
    result = @parser.parse(nil)

    assert_predicate result, :error?
    assert_equal "Empty content", result.error
  end

  test "returns error for invalid XML" do
    result = @parser.parse("<not valid xml>")

    assert_predicate result, :error?
    # Feedjira returns "Unsupported feed format" for invalid content
    assert_predicate result.error, :present?
  end

  test "returns error for non-feed XML" do
    result = @parser.parse('<?xml version="1.0"?><html><body>Not a feed</body></html>')

    assert_predicate result, :error?
  end

  # === URL Normalization ===

  test "fixes relative links in item body" do
    content = Rails.root.join("test/fixtures/github.private.atom").read

    result = @parser.parse(content, base_url: "http://example.com/feed.atom")

    assert_predicate result, :success?
    item = result.items.first
    # Relative links like /bundler/bundler/tree/1-9-stable should be absolute
    assert_includes item.body, "http://example.com/bundler/bundler/tree/1-9-stable"
  end

  test "preserves absolute links in item body" do
    content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test Feed</title>
          <link>http://example.com</link>
          <item>
            <title>Test Item</title>
            <link>http://example.com/item</link>
            <description>&lt;a href="https://other.com/page"&gt;Link&lt;/a&gt;</description>
          </item>
        </channel>
      </rss>
    XML

    result = @parser.parse(content, base_url: "http://example.com/feed.xml")

    assert_predicate result, :success?
    assert_includes result.items.first.body, "https://other.com/page"
  end

  test "handles data URIs in images" do
    content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test Feed</title>
          <link>http://example.com</link>
          <item>
            <title>Test Item</title>
            <link>http://example.com/item</link>
            <description>&lt;img src="data:image/png;base64,ABC123"&gt;</description>
          </item>
        </channel>
      </rss>
    XML

    result = @parser.parse(content, base_url: "http://example.com/feed.xml")

    assert_predicate result, :success?
    # Data URIs should be preserved, not converted
    assert_includes result.items.first.body, "data:image/png;base64,ABC123"
  end

  test "fixes relative image sources" do
    content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test Feed</title>
          <link>http://example.com</link>
          <item>
            <title>Test Item</title>
            <link>http://example.com/item</link>
            <description>&lt;img src="/images/photo.jpg"&gt;</description>
          </item>
        </channel>
      </rss>
    XML

    result = @parser.parse(content, base_url: "http://example.com/feed.xml")

    assert_predicate result, :success?
    assert_includes result.items.first.body, "http://example.com/images/photo.jpg"
  end

  # === Data Normalization ===

  test "handles missing item fields gracefully" do
    content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test Feed</title>
          <link>http://example.com</link>
          <item>
            <title>Minimal Item</title>
          </item>
        </channel>
      </rss>
    XML

    result = @parser.parse(content, base_url: "http://example.com/feed.xml")

    assert_predicate result, :success?
    item = result.items.first

    assert_equal "Minimal Item", item.title
    assert_equal "", item.link
    assert_nil item.author
    assert_nil item.category
  end

  test "normalizes whitespace in titles" do
    content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>  Test Feed  </title>
          <link>http://example.com</link>
          <item>
            <title>  Item with spaces  </title>
            <link>http://example.com/item</link>
          </item>
        </channel>
      </rss>
    XML

    result = @parser.parse(content, base_url: "http://example.com/feed.xml")

    assert_predicate result, :success?
    assert_equal "Test Feed", result.feed_info[:title]
    assert_equal "Item with spaces", result.items.first.title
  end

  # === ParsedItem ===

  test "ParsedItem to_item_attributes includes all fields" do
    content = Rails.root.join("test/fixtures/examlpe.com.feed.xml").read
    result = @parser.parse(content, base_url: "http://example.com/feed.xml")

    attrs = result.items.first.to_item_attributes(feed_id: 42)

    assert_equal 42, attrs[:feed_id]
    assert_equal "北海道で熊がハイキングコースを散策", attrs[:title]
    assert_equal "http://example.com/bearnews/1", attrs[:link]
    assert_kind_of Time, attrs[:stored_on]
  end

  test "ParsedItem to_h returns hash representation" do
    content = Rails.root.join("test/fixtures/examlpe.com.feed.xml").read
    result = @parser.parse(content, base_url: "http://example.com/feed.xml")

    hash = result.items.first.to_h

    assert_equal "北海道で熊がハイキングコースを散策", hash[:title]
    assert_equal "http://example.com/bearnews/1", hash[:link]
    assert hash.key?(:published_at)
  end

  # === ParseResult ===

  test "ParseResult success? and error? are mutually exclusive" do
    content = Rails.root.join("test/fixtures/examlpe.com.feed.xml").read
    result = @parser.parse(content)

    assert_predicate result, :success?
    assert_not result.error?

    error_result = @parser.parse("")

    assert_not error_result.success?
    assert_predicate error_result, :error?
  end
end
