# frozen_string_literal: true

require "test_helper"

class UpdateFeedInformationTest < ActiveSupport::TestCase
  test "does not overwrite feed.link when feed_info[:link] is nil" do
    crawler = Fastladder::Crawler.new(Logger.new(nil))
    feed = create_feed(link: "http://example.com/keep")

    feed_info = { title: "New title", link: nil, description: "desc" }
    crawler.send(:update_feed_information, feed, feed_info)

    assert_equal "http://example.com/keep", feed.link
  end

  test "updates feed.link when feed_info[:link] is present" do
    crawler = Fastladder::Crawler.new(Logger.new(nil))
    feed = create_feed(link: "http://example.com/old")

    feed_info = { title: "New title", link: "http://example.com/new", description: "desc" }
    crawler.send(:update_feed_information, feed, feed_info)

    assert_equal "http://example.com/new", feed.link
  end
end
