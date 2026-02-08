require "test_helper"
require "fastladder/crawler"

class Fastladder::CrawlerTest < ActiveSupport::TestCase
  def setup
    @crawler = Fastladder::Crawler.new(Rails.logger)
    @feed = create_feed
  end

  test "reject_duplicated takes the first when some items have same guid" do
    items = Array.new(2) { Item.new(link: "http://example.com/item", title: "Test", body: "body", guid: "guid", stored_on: Time.now, modified_on: Time.now, created_on: Time.now) }

    result = @crawler.send(:reject_duplicated, @feed, items)
    assert_equal items.take(1), result
  end

  test "reject_duplicated rejects duplicated items" do
    items = [Item.new(link: "http://example.com/item", title: "Test", body: "body", guid: "guid", stored_on: Time.now, modified_on: Time.now, created_on: Time.now)]
    create_item(feed: @feed, guid: "guid", title: "Test", body: "body")
    items.each { |item| item.create_digest }

    result = @crawler.send(:reject_duplicated, @feed, items)
    assert_empty result
  end

  test "update rewrites relative links in item body" do
    atom_body = File.read(File.expand_path("../../fixtures/github.private.atom", __dir__))
    source = Struct.new(:body).new(atom_body)

    @feed.feedlink = "http://example.com/private.atom"
    @feed.save!
    @feed.stub(:favicon_list, []) do
      @crawler.send(:update, @feed, source)
    end

    assert_equal 1, @feed.items.count
    item = @feed.items.first
    doc = Nokogiri::HTML.fragment(item.body)
    assert_equal 1, doc.css('a[href="http://example.com/bundler/bundler/tree/1-9-stable"]').size
  end

  test "cut_off limits items when too large feed" do
    items = Array.new(Fastladder::Crawler::ITEMS_LIMIT + 1) { Item.new(link: "http://example.com/item/#{SecureRandom.hex(4)}", title: "Test", body: "body", guid: SecureRandom.hex(8), stored_on: Time.now, modified_on: Time.now, created_on: Time.now) }
    @feed.items << items

    result = @crawler.send(:cut_off, @feed, items)
    assert_equal Fastladder::Crawler::ITEMS_LIMIT, result.size
  end

  test "new_items_count finds new item" do
    atom_body = File.read(File.expand_path("../../fixtures/github.private.atom", __dir__))
    source = Struct.new(:body).new(atom_body)
    parsed = Feedjira.parse(source.body)
    items = @crawler.send(:build_items, @feed, parsed)

    @feed.feedlink = "http://example.com/private.atom"
    @feed.save!
    @feed.stub(:favicon_list, []) do
      count = @crawler.send(:new_items_count, @feed, items)
      assert_equal 1, count
    end
  end

  test "new_items_count does not find new item when feed not updated since last update" do
    atom_body = File.read(File.expand_path("../../fixtures/github.private.atom", __dir__))
    source = Struct.new(:body).new(atom_body)
    parsed = Feedjira.parse(source.body)

    @feed.feedlink = "http://example.com/private.atom"
    @feed.save!
    @feed.stub(:favicon_list, []) do
      @crawler.send(:update, @feed, source)
      items = @crawler.send(:build_items, @feed, parsed)
      count = @crawler.send(:new_items_count, @feed, items)
      assert_equal 0, count
    end
  end
end
