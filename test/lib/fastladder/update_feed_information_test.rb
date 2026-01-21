# frozen_string_literal: true

require "test_helper"

class UpdateFeedInformationTest < ActiveSupport::TestCase
  Parsed = Struct.new(:title, :url, :description)

  test "does not overwrite feed.link when parsed.url is nil" do
    crawler = Fastladder::Crawler.new(Logger.new(nil))
    feed = FactoryBot.create(:feed, link: "http://example.com/keep")

    parsed = Parsed.new("New title", nil, "desc")
    crawler.send(:update_feed_information, feed, parsed)

    assert_equal "http://example.com/keep", feed.link
  end
end
