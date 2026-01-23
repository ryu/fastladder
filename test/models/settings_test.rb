# frozen_string_literal: true

require "test_helper"

class SettingsTest < ActiveSupport::TestCase
  test "provides max_unread_count" do
    assert_kind_of Integer, Settings.max_unread_count
    assert_predicate Settings.max_unread_count, :positive?
  end

  test "provides subscribe_limit" do
    assert_kind_of Integer, Settings.subscribe_limit
    assert_predicate Settings.subscribe_limit, :positive?
  end

  test "provides save_pin_limit" do
    assert_kind_of Integer, Settings.save_pin_limit
    assert_predicate Settings.save_pin_limit, :positive?
  end

  test "provides crawl_interval" do
    assert_kind_of Integer, Settings.crawl_interval
    assert_predicate Settings.crawl_interval, :positive?
  end

  test "provides allow_tags as array" do
    assert_kind_of Array, Settings.allow_tags
    assert_includes Settings.allow_tags, "a"
    assert_includes Settings.allow_tags, "img"
  end

  test "provides allow_attributes as array" do
    assert_kind_of Array, Settings.allow_attributes
    assert_includes Settings.allow_attributes, "href"
    assert_includes Settings.allow_attributes, "src"
  end

  test "provides default_favicon path" do
    assert_kind_of String, Settings.default_favicon
    assert_includes Settings.default_favicon, "default.png"
  end
end
