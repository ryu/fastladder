# frozen_string_literal: true

require "test_helper"

class UserHelperTest < ActionView::TestCase
  include UserHelper

  setup do
    @member = create_member(password: "test", password_confirmation: "test")
    @feed = create_feed
  end

  test "subscribe_button returns nil when not logged in" do
    # current_member returns nil when not logged in
    def current_member
      nil
    end

    assert_nil subscribe_button("https://example.com/feed.xml")
  end

  test "subscribe_button returns add link when not subscribed" do
    def current_member
      @member
    end

    result = subscribe_button("https://example.com/new-feed.xml")

    assert_match(/add/, result)
    assert_match(/subscribe/, result)
    assert_match(/href/, result)
  end

  test "subscribe_button returns subscribed status when already subscribed" do
    subscription = @member.subscribe_feed(@feed.feedlink)

    def current_member
      @member
    end

    result = subscribe_button(@feed.feedlink)

    assert_match(/subscribed/, result)
    assert_match(/subs_edit/, result)
    assert_match(/edit:#{subscription.id}/, result)
  end
end
