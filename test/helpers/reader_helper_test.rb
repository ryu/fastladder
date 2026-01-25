# frozen_string_literal: true

require "test_helper"

class ReaderHelperTest < ActionView::TestCase
  include ReaderHelper

  # --- Constants ---

  test "VIEW_MODES contains expected modes" do
    assert_includes ReaderHelper::VIEW_MODES.keys, "flat"
    assert_includes ReaderHelper::VIEW_MODES.keys, "folder"
    assert_includes ReaderHelper::VIEW_MODES.keys, "rate"
    assert_includes ReaderHelper::VIEW_MODES.keys, "subscribers"
  end

  test "SORT_MODES contains expected modes" do
    assert_includes ReaderHelper::SORT_MODES.keys, "modified_on"
    assert_includes ReaderHelper::SORT_MODES.keys, "unread_count"
    assert_includes ReaderHelper::SORT_MODES.keys, "title:reverse"
    assert_includes ReaderHelper::SORT_MODES.keys, "rate"
  end

  # --- Tier 1 Templates ---

  test "render_clip_register returns static HTML" do
    result = render_clip_register

    assert_includes result, "clip_register"
    assert_includes result, "livedoor"
  end

  test "render_viewmode_item renders menu item with mode" do
    result = render_viewmode_item("flat", "flat")

    assert_includes result, "flat"
    assert_includes result, "checked"
    assert_includes result, "menu-item"
  end

  test "render_viewmode_item without current mode does not add checked" do
    result = render_viewmode_item("folder", nil)

    assert_includes result, "folder"
    assert_not_includes result, "checked"
  end

  test "render_sortmode_item renders menu item with mode" do
    result = render_sortmode_item("rate", "rate")

    assert_includes result, "Rating"
    assert_includes result, "checked"
  end

  test "render_folder_item renders folder menu item" do
    result = render_folder_item("Tech")

    assert_includes result, "Tech"
    assert_includes result, "menu-item"
  end

  test "render_subscribe_folder renders folder display" do
    result = render_subscribe_folder("News", unread_count: 5)

    assert_includes result, "News"
    assert_includes result, "(5)"
  end

  # --- Tier 2 Templates ---

  test "render_menu_item renders with action" do
    result = render_menu_item(title: "Reload", action: "Control.reload()")

    assert_includes result, "Reload"
    assert_includes result, "Control.reload()"
  end

  test "render_pin_item renders with icon and link" do
    pin = { title: "Article", link: "http://example.com", icon: "/img/icon/feed.gif" }
    result = render_pin_item(pin, target: true)

    assert_includes result, "Article"
    assert_includes result, "http://example.com"
    assert_includes result, "pin-target"
  end

  test "render_subscribe_item renders subscription" do
    subscription = subscriptions(:subscription_one)

    result = render_subscribe_item(subscription, unread_count: 10)

    assert_includes result, "(10)"
    assert_includes result, "subscription-item"
    assert_includes result, "subs_item_#{subscription.id}"
  end

  # --- Tier 3 Templates ---

  test "render_discover_item renders unsubscribed feed" do
    feed = { feedlink: "http://example.com/feed", link: "http://example.com", title: "Example", subscribers_count: 5 }
    result = render_discover_item(feed, subscribed: false)

    assert_includes result, "Example"
    assert_includes result, "Add"
    assert_includes result, "5"
    assert_not_includes result, "[Subscribed]"
  end

  test "render_discover_item renders subscribed feed" do
    feed = { feedlink: "http://example.com/feed", link: "http://example.com", title: "Example", subscribers_count: 5 }
    result = render_discover_item(feed, subscribed: true)

    assert_includes result, "Example"
    assert_includes result, "Unsubscribe"
    assert_includes result, "[Subscribed]"
  end

  # --- Tier 4 Templates ---

  test "render_inbox_item renders feed item" do
    item = {
      id: 123,
      title: "Test Article",
      link: "http://example.com/article",
      body: "<p>Content</p>",
      relative_date: "2 hours ago"
    }
    result = render_inbox_item(item, item_count: 1, pinned: false)

    assert_includes result, "Test Article"
    assert_includes result, "item_123"
    assert_includes result, "2 hours ago"
  end

  test "render_inbox_item renders pinned item" do
    item = { id: 456, title: "Pinned", link: "http://example.com", body: "" }
    result = render_inbox_item(item, pinned: true, pin_active: "pin_active")

    assert_includes result, "pinned"
    assert_includes result, "pin_active"
  end

  test "clip_page_link generates correct URL" do
    link = clip_page_link("http://example.com/page")

    assert_equal "http://clip.livedoor.com/page/http%3A%2F%2Fexample.com%2Fpage", link
  end
end
