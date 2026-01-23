# frozen_string_literal: true

require "test_helper"

class Api::Subscriptions::FoldersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "test", password_confirmation: "test")
    @feed = create_feed(feedlink: "http://example.com/feed.xml")
    @subscription = create_subscription(feed: @feed, member: @member)
    @folder = create_folder(member: @member)
  end

  test "POST /api/feed/move moves subscription to folder by name" do
    post "/api/feed/move",
         params: { subscribe_id: @subscription.id, to: @folder.name },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert json["isSuccess"]
    @subscription.reload

    assert_equal @folder.id, @subscription.folder_id
  end

  test "POST /api/feed/move moves subscription to folder by id" do
    post "/api/feed/move",
         params: { subscribe_id: @subscription.id, to: @folder.id.to_s },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    json = response.parsed_body

    assert json["isSuccess"]
    @subscription.reload

    assert_equal @folder.id, @subscription.folder_id
  end

  test "POST /api/feed/move moves multiple subscriptions" do
    feed2 = create_feed(feedlink: "http://example.com/feed2.xml")
    sub2 = create_subscription(feed: feed2, member: @member)

    post "/api/feed/move",
         params: { subscribe_id: "#{@subscription.id},#{sub2.id}", to: @folder.name },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    @subscription.reload
    sub2.reload

    assert_equal @folder.id, @subscription.folder_id
    assert_equal @folder.id, sub2.folder_id
  end

  test "POST /api/feed/move clears folder when target not found" do
    @subscription.update!(folder_id: @folder.id)
    post "/api/feed/move",
         params: { subscribe_id: @subscription.id, to: "nonexistent" },
         headers: { "HTTP_COOKIE" => login_cookie }

    assert_response :success
    @subscription.reload

    assert_nil @subscription.folder_id
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
