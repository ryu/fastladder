# frozen_string_literal: true

require "test_helper"

# Tests for URL normalization in FeedParser
# (Previously tested via Crawler#fixup_relative_links, now in FeedParser)
class FixupRelativeLinksTest < ActiveSupport::TestCase
  def setup
    @parser = Fastladder::FeedParser.new(logger: Logger.new(nil))
  end

  test "converts relative links to absolute" do
    content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test</title>
          <link>http://example.com</link>
          <item>
            <title>Item</title>
            <link>http://example.com/item</link>
            <description>&lt;p&gt;&lt;a href="/a"&gt;A&lt;/a&gt;&lt;/p&gt;</description>
          </item>
        </channel>
      </rss>
    XML

    result = @parser.parse(content, base_url: "http://example.com/feed")

    assert_predicate result, :success?
    assert_includes result.items.first.body, 'href="http://example.com/a"'
  end

  test "returns as-is when there are no links" do
    content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test</title>
          <link>http://example.com</link>
          <item>
            <title>Item</title>
            <link>http://example.com/item</link>
            <description>&lt;p&gt;Hello&lt;/p&gt;</description>
          </item>
        </channel>
      </rss>
    XML

    result = @parser.parse(content, base_url: "http://example.com/feed")

    assert_predicate result, :success?
    assert_includes result.items.first.body, "<p>Hello</p>"
  end

  test "handles invalid URLs gracefully" do
    content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test</title>
          <link>http://example.com</link>
          <item>
            <title>Item</title>
            <link>http://example.com/item</link>
            <description>&lt;p&gt;&lt;a href="http://%ZZ"&gt;X&lt;/a&gt;&lt;/p&gt;</description>
          </item>
        </channel>
      </rss>
    XML

    result = @parser.parse(content, base_url: "http://example.com/feed")

    # Should not crash, and should either normalize or preserve the URL
    assert_predicate result, :success?
    assert_predicate result.items.first.body, :present?
  end
end
