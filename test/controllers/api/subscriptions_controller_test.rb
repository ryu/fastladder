# frozen_string_literal: true

require "test_helper"

class Api::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "test", password_confirmation: "test")
    @feed = create_feed(feedlink: "http://example.com/feed.xml")
    @subscription = create_subscription(feed: @feed, member: @member)
    @folder = create_folder(member: @member)
  end

  # Tests via legacy routes for backward compatibility

  test "POST /api/feed/subscribe creates subscription" do
    new_feed = create_feed(feedlink: "http://example.com/new-feed.xml")
    post "/api/feed/subscribe",
         params: { feedlink: new_feed.feedlink },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert json["isSuccess"]
    assert json["subscribe_id"]
  end

  test "POST /api/feed/subscribe fails without feedlink" do
    post "/api/feed/subscribe",
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert_not json["isSuccess"]
  end

  test "GET /api/feed/subscribed returns subscription info" do
    get "/api/feed/subscribed",
        params: { subscribe_id: @subscription.id },
        headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert_equal @subscription.id, json["subscribe_id"]
  end

  test "POST /api/feed/subscribed returns subscription info" do
    post "/api/feed/subscribed",
         params: { feedlink: @feed.feedlink },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert_equal @subscription.id, json["subscribe_id"]
  end

  test "POST /api/feed/subscribed fails with invalid subscription" do
    post "/api/feed/subscribed",
         params: { subscribe_id: 999_999 },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert_not json["isSuccess"]
  end

  test "POST /api/feed/update updates subscription settings" do
    post "/api/feed/update",
         params: { subscribe_id: @subscription.id, rate: 3, folder_id: @folder.id },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert json["isSuccess"]
    @subscription.reload

    assert_equal 3, @subscription.rate
    assert_equal @folder.id, @subscription.folder_id
  end

  test "POST /api/feed/update fails without subscribe_id" do
    post "/api/feed/update",
         params: { rate: 3 },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert_not json["isSuccess"]
  end

  test "POST /api/feed/unsubscribe removes subscription" do
    assert_difference("Subscription.count", -1) do
      post "/api/feed/unsubscribe",
           params: { subscribe_id: @subscription.id },
           headers: { "HTTP_COOKIE" => login_cookie }
    end
    assert_response :success
    json = response.parsed_body

    assert json["isSuccess"]
  end

  test "POST /api/feed/unsubscribe fails without subscribe_id" do
    post "/api/feed/unsubscribe",
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert_not json["isSuccess"]
  end

  test "POST /api/feed/unsubscribe returns turbo_stream when requested" do
    subscription_id = @subscription.id
    assert_difference("Subscription.count", -1) do
      post "/api/feed/unsubscribe",
           params: { subscribe_id: subscription_id },
           headers: {
             "HTTP_COOKIE" => login_cookie,
             "Accept" => "text/vnd.turbo-stream.html"
           }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_includes response.body, "subscription-#{subscription_id}"
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, 'action="remove"'
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
