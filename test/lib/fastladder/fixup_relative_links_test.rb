# frozen_string_literal: true

require "test_helper"

class FixupRelativeLinksTest < ActiveSupport::TestCase
  test "converts relative links to absolute" do
    crawler = Fastladder::Crawler.new(Logger.new(nil))

    html = %(<p><a href="/a">A</a></p>)
    fixed = crawler.send(:fixup_relative_links, "http://example.com/feed", html, logger: Logger.new(nil))

    assert_includes fixed, %(href="http://example.com/a")
  end

  test "returns as-is when there are no links" do
    crawler = Fastladder::Crawler.new(Logger.new(nil))

    html = "<p>Hello</p>"
    fixed = crawler.send(:fixup_relative_links, "http://example.com/feed", html, logger: Logger.new(nil))

    assert_equal html, fixed
  end

  test "normalizes odd hrefs" do
    crawler = Fastladder::Crawler.new(Logger.new(nil))

    html = %(<p><a href="http://%ZZ">X</a></p>)
    fixed = crawler.send(:fixup_relative_links, "http://example.com/feed", html, logger: Logger.new(nil))

    assert_includes fixed, %(<a href="http://%25zz/">)
  end
end
