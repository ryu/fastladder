# frozen_string_literal: true

require "test_helper"

class Api::Subscriptions::RatesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "test", password_confirmation: "test")
    @feed = create_feed(feedlink: "http://example.com/feed.xml")
    @subscription = create_subscription(feed: @feed, member: @member, rate: 0)
  end

  test "POST /api/feed/set_rate updates subscription rate" do
    post "/api/feed/set_rate",
         params: { subscribe_id: @subscription.id, rate: 4 },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert json["isSuccess"]
    @subscription.reload

    assert_equal 4, @subscription.rate
  end

  test "POST /api/feed/set_rate ignores invalid rate" do
    post "/api/feed/set_rate",
         params: { subscribe_id: @subscription.id, rate: 10 },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    @subscription.reload

    assert_equal 0, @subscription.rate
  end

  test "POST /api/feed/set_rate fails without subscribe_id" do
    post "/api/feed/set_rate",
         params: { rate: 3 },
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
