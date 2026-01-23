# frozen_string_literal: true

require "test_helper"

class Api::Subscriptions::NotificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "test", password_confirmation: "test")
    @feed = create_feed(feedlink: "http://example.com/feed.xml")
    @subscription = create_subscription(feed: @feed, member: @member, ignore_notify: false)
  end

  test "POST /api/feed/set_notify updates notification setting" do
    post "/api/feed/set_notify",
         params: { subscribe_id: @subscription.id, ignore: "1" },
         headers: { "HTTP_COOKIE" => login_cookie }
    assert_response :success
    json = response.parsed_body
    assert json["isSuccess"]
    @subscription.reload
    assert @subscription.ignore_notify
  end

  test "POST /api/feed/set_notify updates multiple subscriptions" do
    feed2 = create_feed(feedlink: "http://example.com/feed2.xml")
    sub2 = create_subscription(feed: feed2, member: @member, ignore_notify: false)

    post "/api/feed/set_notify",
         params: { subscribe_id: "#{@subscription.id},#{sub2.id}", ignore: "1" },
         headers: { "HTTP_COOKIE" => login_cookie }
    assert_response :success
    @subscription.reload
    sub2.reload
    assert @subscription.ignore_notify
    assert sub2.ignore_notify
  end

  test "POST /api/feed/set_notify fails with invalid ignore value" do
    post "/api/feed/set_notify",
         params: { subscribe_id: @subscription.id, ignore: "invalid" },
         headers: { "HTTP_COOKIE" => login_cookie }
    assert_response :success
    json = response.parsed_body
    assert_not json["isSuccess"]
  end

  private

  def login_cookie
    post "/session", params: {
      username: @member.username,
      password: "test"
    }
    response.headers["Set-Cookie"]
  end
end
