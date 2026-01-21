require "test_helper"

class FaviconTest < ActiveSupport::TestCase
  test "belongs to feed" do
    feed = FactoryBot.create(:feed)
    favicon = Favicon.create!(feed: feed, image: "PNG data")
    assert_equal feed, favicon.feed
  end

  test "stores binary image data" do
    feed = FactoryBot.create(:feed)
    image_data = "\x89PNG\r\n\x1a\n".b
    favicon = Favicon.create!(feed: feed, image: image_data)
    favicon.reload
    assert_equal image_data, favicon.image
  end

  test "feed can have one favicon" do
    feed = FactoryBot.create(:feed)
    favicon = Favicon.create!(feed: feed, image: "data")
    assert_equal favicon, feed.favicon
  end
end
