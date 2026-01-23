# frozen_string_literal: true

require "test_helper"

class MobileControllerTest < ActionController::TestCase
  def setup
    @member = create_member(password: "password")
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
    get :index
    assert_redirected_to "/login"
  end

  test "GET index renders without layout when logged in" do
    get :index, session: { member_id: @member.id }
    assert_response :success
    assert_template :index
  end

  test "GET index shows subscriptions with unread items" do
    get :index, session: { member_id: @member.id }
    assert_response :success
    assert_includes assigns(:subscriptions), @subscription
  end

  test "GET index excludes subscriptions without unread items" do
    @subscription.update!(has_unread: false, viewed_on: Time.current)

    get :index, session: { member_id: @member.id }
    assert_response :success
    assert_not_includes assigns(:subscriptions), @subscription
  end

  # Read feed tests
  test "GET read_feed requires login" do
    get :read_feed, params: { feed_id: @subscription.id }
    assert_redirected_to "/login"
  end

  test "GET read_feed renders items" do
    get :read_feed, params: { feed_id: @subscription.id }, session: { member_id: @member.id }
    assert_response :success
    assert_template :read_feed
    assert_equal @subscription, assigns(:subscription)
  end

  test "GET read_feed shows unread items" do
    get :read_feed, params: { feed_id: @subscription.id }, session: { member_id: @member.id }
    assert_response :success
    assert_includes assigns(:items), @item
  end

  # Mark as read tests
  test "POST mark_as_read requires login" do
    post :mark_as_read, params: { feed_id: @subscription.id, timestamp: Time.current.to_i }
    assert_redirected_to "/login"
  end

  test "POST mark_as_read updates subscription" do
    timestamp = Time.current.to_i

    post :mark_as_read, params: {
      feed_id: @subscription.id,
      timestamp: timestamp
    }, session: { member_id: @member.id }

    assert_redirected_to "/mobile"
    @subscription.reload
    assert_equal false, @subscription.has_unread
    assert_equal Time.at(timestamp + 1).to_i, @subscription.viewed_on.to_i
  end

  # Pin tests
  test "POST pin requires login" do
    post :pin, params: { item_id: @item.id }
    assert_redirected_to "/login"
  end

  test "POST pin creates pin for item" do
    assert_difference "Pin.count", 1 do
      post :pin, params: { item_id: @item.id }, session: { member_id: @member.id }
    end

    assert_redirected_to "/mobile/#{@item.feed_id}#item-#{@item.id}"

    pin = @member.pins.last
    assert_equal @item.link, pin.link
    assert_equal @item.title, pin.title
  end

  test "POST pin handles duplicate gracefully" do
    @member.pins.create!(link: @item.link, title: @item.title)

    assert_no_difference "Pin.count" do
      post :pin, params: { item_id: @item.id }, session: { member_id: @member.id }
    end

    assert_redirected_to "/mobile/#{@item.feed_id}#item-#{@item.id}"
  end
end
