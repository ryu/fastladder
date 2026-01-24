# frozen_string_literal: true

require "application_system_test_case"

class MobileTest < ApplicationSystemTestCase
  test "can view mobile index with unread feeds" do
    member = Member.create!(username: "mobileuser1", password: "testpass", password_confirmation: "testpass")
    feed = Feed.create!(
      feedlink: "https://example.com/feed1.xml",
      title: "Mobile Test Feed",
      link: "https://example.com",
      description: "A test feed"
    )
    Subscription.create!(member: member, feed: feed, has_unread: true, viewed_on: 1.day.ago)
    Item.create!(feed: feed, title: "Test Item", link: "https://example.com/item", body: "Body", stored_on: Time.current)

    visit "/login"
    fill_in "username", with: "mobileuser1"
    fill_in "password", with: "testpass"
    click_on "Sign In"

    assert_current_path "/reader/"

    visit "/mobile"

    assert_text "Mobile Test Feed"
  end

  test "can view pins page with pinned items" do
    member = Member.create!(username: "mobileuser2", password: "testpass", password_confirmation: "testpass")
    member.pins.create!(link: "https://example.com/pinned", title: "My Pinned Article")

    visit "/login"
    fill_in "username", with: "mobileuser2"
    fill_in "password", with: "testpass"
    click_on "Sign In"

    assert_current_path "/reader/"

    visit "/pins"

    assert_text "Pins"
    assert_text "My Pinned Article"
    assert_link "Back to feeds"
  end
end
