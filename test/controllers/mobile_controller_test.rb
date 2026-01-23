# frozen_string_literal: true

require "test_helper"

class MobileControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "password", password_confirmation: "password")
    @feed = create_feed(title: "Test Feed")
    @subscription = create_subscription(
      member: @member,
      feed: @feed,
      has_unread: true,
      viewed_on: 1.day.ago
    )
    @item = create_item(feed: @feed, stored_on: Time.current)
  end

  # Index tests
  test "GET index requires login" do
    get "/mobile"

    assert_redirected_to "/login"
  end

  test "GET index renders when logged in" do
    login_as(@member, password: "password")
    get "/mobile"

    assert_response :success
  end

  # Read feed tests
  test "GET read_feed requires login" do
    get "/mobile/#{@subscription.id}"

    assert_redirected_to "/login"
  end

  test "GET read_feed renders items" do
    login_as(@member, password: "password")
    get "/mobile/#{@subscription.id}"

    assert_response :success
  end

  # Mark as read tests
  test "GET mark_as_read requires login" do
    get "/mobile/#{@subscription.id}/read", params: { timestamp: Time.current.to_i }

    assert_redirected_to "/login"
  end

  test "GET mark_as_read updates subscription" do
    timestamp = Time.current.to_i
    login_as(@member, password: "password")
    get "/mobile/#{@subscription.id}/read", params: { timestamp: timestamp }

    assert_redirected_to "/mobile"
    @subscription.reload

    assert_not @subscription.has_unread
    assert_equal Time.at(timestamp + 1).to_i, @subscription.viewed_on.to_i
  end

  # Pin tests
  test "GET pin requires login" do
    get "/mobile/#{@item.id}/pin"

    assert_redirected_to "/login"
  end

  test "GET pin creates pin for item" do
    login_as(@member, password: "password")
    assert_difference "Pin.count", 1 do
      get "/mobile/#{@item.id}/pin"
    end
    assert_redirected_to "/mobile/#{@item.feed_id}#item-#{@item.id}"

    pin = @member.pins.last

    assert_equal @item.link, pin.link
    assert_equal @item.title, pin.title
  end

  test "GET pin handles duplicate gracefully" do
    @member.pins.create!(link: @item.link, title: @item.title)
    login_as(@member, password: "password")
    assert_no_difference "Pin.count" do
      get "/mobile/#{@item.id}/pin"
    end
    assert_redirected_to "/mobile/#{@item.feed_id}#item-#{@item.id}"
  end

  private

  def login_as(member, password:)
    post "/session", params: { username: member.username, password: password }
  end
end
