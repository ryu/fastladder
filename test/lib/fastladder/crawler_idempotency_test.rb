# frozen_string_literal: true

require "test_helper"
require "fastladder/crawler"

class Fastladder::CrawlerIdempotencyTest < ActiveSupport::TestCase
  def setup
    @crawler = Fastladder::Crawler.new(Rails.logger)
    @feed = create_feed
  end

  test "upsert_item creates new item when not exists" do
    item = build_item_with_fixed_guid(feed: @feed)
    item.create_digest
    result = { new_items: 0, updated_items: 0 }

    @crawler.send(:upsert_item, @feed, item, result)

    assert_equal 1, result[:new_items]
    assert_equal 0, result[:updated_items]
    assert_equal 1, @feed.items.count
  end

  test "upsert_item updates existing item when guid matches" do
    # Create existing item
    existing = create_item_with_fixed_guid(feed: @feed)
    original_version = existing.version

    # Create new item with same guid but different content
    item = build_item_with_fixed_guid(feed: @feed)
    item.title = "Updated Title"
    item.body = "Completely different body content"
    item.create_digest

    result = { new_items: 0, updated_items: 0 }

    @crawler.send(:upsert_item, @feed, item, result)

    assert_equal 0, result[:new_items]
    assert_equal 1, result[:updated_items]
    assert_equal 1, @feed.items.count

    existing.reload

    assert_equal "Updated Title", existing.title
    assert_equal original_version + 1, existing.version
  end

  test "upsert_item does not count as update when content is almost same" do
    # Create existing item
    existing = create_item_with_fixed_guid(feed: @feed)

    # Create new item with same guid and nearly identical content (only whitespace diff)
    item = build_item_with_fixed_guid(feed: @feed)
    item.title = existing.title
    item.body = existing.body
    item.create_digest

    result = { new_items: 0, updated_items: 0 }

    @crawler.send(:upsert_item, @feed, item, result)

    assert_equal 0, result[:new_items]
    assert_equal 0, result[:updated_items]
  end

  test "processing same items twice is idempotent" do
    items = [
      build_item_with_guid("guid-1", feed: @feed),
      build_item_with_guid("guid-2", feed: @feed),
      build_item_with_guid("guid-3", feed: @feed)
    ]
    items.each(&:create_digest)

    # First pass
    result1 = { new_items: 0, updated_items: 0 }
    @crawler.send(:update_or_insert_items_to_feed, @feed, items.dup, result1)

    assert_equal 3, result1[:new_items]
    assert_equal 3, @feed.items.count

    # Second pass with same items
    result2 = { new_items: 0, updated_items: 0 }
    @crawler.send(:update_or_insert_items_to_feed, @feed, items.dup, result2)

    # Should not create new items
    assert_equal 0, result2[:new_items]
    assert_equal 3, @feed.items.count
  end

  test "handles uniqueness violation gracefully" do
    item = build_item_with_fixed_guid(feed: @feed)
    item.create_digest
    result = { new_items: 0, updated_items: 0 }

    # Simulate race condition: create item right after find_by returns nil
    # by inserting before our insert
    original_shovel = @feed.items.method(:<<)

    first_call = true
    @feed.items.define_singleton_method(:<<) do |new_item|
      if first_call
        first_call = false
        # Simulate another process inserting first
        Item.create!(
          feed_id: new_item.feed_id,
          guid: new_item.guid,
          link: "http://other.example.com",
          title: "Race condition item",
          body: "Created by another process"
        )
      end
      original_shovel.call(new_item)
    end

    # This should handle the uniqueness violation and retry as update
    @crawler.send(:upsert_item, @feed, item, result)

    # Restore original method
    @feed.items.define_singleton_method(:<<) { |new_item| original_shovel.call(new_item) }

    # The item should exist (either from original insert or update)
    assert @feed.items.exists?(guid: item.guid)
  end

  private

  def build_item_with_guid(guid, feed:)
    Item.new(
      feed_id: feed.id,
      guid: guid,
      link: "http://example.com/items/#{guid}",
      title: "Item #{guid}",
      body: "Body for #{guid}",
      stored_on: Time.zone.now
    )
  end
end
