require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "as_json includes id" do
    item = items(:item_one)
    json = item.as_json
    assert_includes json, :id
    assert_equal item.id, json[:id]
  end

  test "as_json includes link" do
    item = items(:item_one)
    json = item.as_json
    assert_includes json, :link
    assert_equal item.link, json[:link]
  end

  test "as_json includes title" do
    item = items(:item_one)
    json = item.as_json
    assert_includes json, :title
    assert_equal item.title, json[:title]
  end

  test "as_json includes body" do
    item = items(:item_one)
    json = item.as_json
    assert_includes json, :body
    assert_equal item.body, json[:body]
  end

  test "as_json includes author" do
    item = items(:item_one)
    json = item.as_json
    assert_includes json, :author
    assert_equal item.author, json[:author]
  end

  test "as_json includes category" do
    item = items(:item_one)
    json = item.as_json
    assert_includes json, :category
    assert_equal item.category, json[:category]
  end

  test "as_json includes modified_on as timestamp" do
    item = items(:item_one)
    json = item.as_json
    assert_includes json, :modified_on
    assert_equal item.modified_on.to_i, json[:modified_on]
  end

  test "as_json includes created_on as timestamp" do
    item = items(:item_one)
    json = item.as_json
    assert_includes json, :created_on
    assert_equal item.created_on.to_i, json[:created_on]
  end

  test "stored_since with nil returns all items" do
    item_1 = create_item(stored_on: 20.hours.ago)
    item_2 = create_item(stored_on: 10.hours.ago)
    result = Item.stored_since(nil)
    assert_includes result, item_1
    assert_includes result, item_2
  end

  test "stored_since with time filters items" do
    item_1 = create_item(stored_on: 20.hours.ago)
    item_2 = create_item(stored_on: 10.hours.ago)
    result = Item.stored_since(15.hours.ago)
    refute_includes result, item_1
    assert_includes result, item_2
  end

  test "recent returns items in correct order" do
    item_1 = create_item(created_on: 1.hour.ago)
    item_2 = create_item(created_on: 3.hours.ago)
    item_3 = create_item(created_on: 2.hours.ago)
    assert_equal [item_1, item_3, item_2], Item.recent.where(id: [item_1.id, item_2.id, item_3.id])
  end

  test "recent with limit returns limited items" do
    # Clear existing items for this test
    feed = create_feed
    item_1 = create_item(feed: feed, created_on: 1.hour.ago)
    item_2 = create_item(feed: feed, created_on: 3.hours.ago)
    item_3 = create_item(feed: feed, created_on: 2.hours.ago)
    result = Item.where(feed: feed).recent(2)
    assert_equal [item_1, item_3], result
  end

  test "recent with limit and offset returns offset items" do
    feed = create_feed
    item_1 = create_item(feed: feed, created_on: 1.hour.ago)
    item_2 = create_item(feed: feed, created_on: 3.hours.ago)
    item_3 = create_item(feed: feed, created_on: 2.hours.ago)
    result = Item.where(feed: feed).recent(1, 1)
    assert_equal [item_3], result
  end

  test "item has default title" do
    item = create_item(title: nil)
    refute_nil item.title
  end

  test "guid defaults to link" do
    item = create_item(guid: nil)
    assert_equal item.link, item.guid
  end
end
