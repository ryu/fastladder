# frozen_string_literal: true

require "test_helper"

class Api::Subscriptions::VisibilitiesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "test", password_confirmation: "test")
    @feed = create_feed(feedlink: "http://example.com/feed.xml")
    @subscription = create_subscription(feed: @feed, member: @member, public: false)
  end

  test "POST /api/feed/set_public updates visibility setting" do
    post "/api/feed/set_public",
         params: { subscribe_id: @subscription.id, public: "1" },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert json["isSuccess"]
    @subscription.reload

    assert @subscription.public
  end

  test "POST /api/feed/set_public updates multiple subscriptions" do
    feed2 = create_feed(feedlink: "http://example.com/feed2.xml")
    sub2 = create_subscription(feed: feed2, member: @member, public: false)

    post "/api/feed/set_public",
         params: { subscribe_id: "#{@subscription.id},#{sub2.id}", public: "1" },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    @subscription.reload
    sub2.reload

    assert @subscription.public
    assert sub2.public
  end

  test "POST /api/feed/set_public fails with invalid public value" do
    post "/api/feed/set_public",
         params: { subscribe_id: @subscription.id, public: "invalid" },
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
