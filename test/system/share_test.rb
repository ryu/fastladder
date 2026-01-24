# frozen_string_literal: true

require "application_system_test_case"

class ShareTest < ApplicationSystemTestCase
  test "can view share page" do
    Member.create!(username: "shareuser1", password: "testpass", password_confirmation: "testpass")

    visit "/login"
    fill_in "username", with: "shareuser1"
    fill_in "password", with: "testpass"
    click_on "Sign In"

    assert_current_path "/reader/"

    visit "/share"

    assert_text "Manage Sharing"
    assert_text "Sharing:"
    assert_button "Enable Sharing"
  end

  test "can view share page with subscriptions" do
    member = Member.create!(username: "shareuser2", password: "testpass", password_confirmation: "testpass")
    feed = Feed.create!(
      feedlink: "https://example.com/share-feed.xml",
      title: "Share Test Feed",
      link: "https://example.com",
      description: "A test feed for sharing"
    )
    Subscription.create!(member: member, feed: feed, has_unread: false)

    visit "/login"
    fill_in "username", with: "shareuser2"
    fill_in "password", with: "testpass"
    click_on "Sign In"

    assert_current_path "/reader/"

    visit "/share"

    assert_text "Manage Sharing"
    assert_text "Target"
    assert_text "Subscribers"
    assert_text "Title or URL"
    assert_text "Folders"
    assert_text "Ratings"
  end
end
