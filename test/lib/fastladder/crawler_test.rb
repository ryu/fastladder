require "test_helper"
require "fastladder/crawler"

class Fastladder::CrawlerTest < ActiveSupport::TestCase
  def setup
    @crawler = Fastladder::Crawler.new(Rails.logger)
    @feed = create_feed
  end

  test "reject_duplicated takes the first when some items have same guid" do
    items = [build_item_with_fixed_guid, build_item_with_fixed_guid]

    result = @crawler.send(:reject_duplicated, @feed, items)
    assert_equal items.take(1), result
  end

  test "reject_duplicated rejects duplicated items" do
    items = [build_item_with_fixed_guid]
    create_item_with_fixed_guid(feed: @feed)
    items.each { |item| item.create_digest }

    result = @crawler.send(:reject_duplicated, @feed, items)
    assert_empty result
  end

  test "update rewrites relative links in item body" do
    atom_body = File.read(File.expand_path("../../fixtures/github.private.atom", __dir__))
    source = Struct.new(:body).new(atom_body)

    @feed.feedlink = "http://example.com/private.atom"
    @feed.save!
    @feed.stub(:favicon_candidates, []) do
      @crawler.send(:update, @feed, source)
    end

    assert_equal 1, @feed.items.count
    item = @feed.items.first
    doc = Nokogiri::HTML.fragment(item.body)
    assert_equal 1, doc.css('a[href="http://example.com/bundler/bundler/tree/1-9-stable"]').size
  end

  test "cut_off limits items when too large feed" do
    items = build_items(Fastladder::Crawler::ITEMS_LIMIT + 1)
    @feed.items << items

    result = @crawler.send(:cut_off, @feed, items)
    assert_equal Fastladder::Crawler::ITEMS_LIMIT, result.size
  end

  test "new_items_count finds new item" do
    atom_body = File.read(File.expand_path("../../fixtures/github.private.atom", __dir__))

    # Use FeedParser to parse the content
    parser = Fastladder::FeedParser.new
    parse_result = parser.parse(atom_body, base_url: "http://example.com/private.atom")
    items = parse_result.items.map do |parsed_item|
      item = Item.new(parsed_item.to_item_attributes(feed_id: @feed.id))
      item.create_digest
      item
    end

    @feed.feedlink = "http://example.com/private.atom"
    @feed.save!
    @feed.stub(:favicon_candidates, []) do
      count = @crawler.send(:new_items_count, @feed, items)
      assert_equal 1, count
    end
  end

  test "new_items_count does not find new item when feed not updated since last update" do
    atom_body = File.read(File.expand_path("../../fixtures/github.private.atom", __dir__))
    source = Struct.new(:body).new(atom_body)

    @feed.feedlink = "http://example.com/private.atom"
    @feed.save!
    @feed.stub(:favicon_candidates, []) do
      # First update - inserts the item
      @crawler.send(:update, @feed, source)

      # Parse again and build items
      parser = Fastladder::FeedParser.new
      parse_result = parser.parse(atom_body, base_url: @feed.feedlink)
      items = parse_result.items.map do |parsed_item|
        item = Item.new(parsed_item.to_item_attributes(feed_id: @feed.id))
        item.create_digest
        item
      end

      count = @crawler.send(:new_items_count, @feed, items)
      assert_equal 0, count
    end
  end
end
