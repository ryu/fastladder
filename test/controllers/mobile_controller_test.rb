require "test_helper"

class MobileControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = members(:bulkneets)
    @other_member = members(:other)
    @feed = feeds(:default)
    @item = create_item(feed: @feed)
    @subscription = subscriptions(:default)
    @other_subscription = create_subscription(feed: @feed, member: @other_member)
  end

  # Security tests - Unauthorized access prevention
  test "read_feed prevents access to other user's subscription" do
    login_as(@other_member, "pass")

    get "/mobile/#{@subscription.id}"

    assert_response :not_found
  end

  test "mark_as_read prevents access to other user's subscription" do
    login_as(@other_member, "pass")
    @subscription.update!(has_unread: true)
    original_viewed_on = @subscription.viewed_on

    post "/mobile/#{@subscription.id}/read", params: { timestamp: Time.now.to_i }

    assert_response :not_found
    # Verify subscription was not modified
    @subscription.reload
    assert_equal true, @subscription.has_unread, "has_unread should not have been modified"
    assert_nil @subscription.viewed_on, "viewed_on should not have been modified"
  end

  test "pin prevents access to items from unsubscribed feeds" do
    # Create a feed that only @member is subscribed to
    unsubscribed_feed = create_feed(feedlink: "http://example.com/unsubscribed")
    unsubscribed_item = create_item(feed: unsubscribed_feed)
    create_subscription(feed: unsubscribed_feed, member: @member)

    login_as(@other_member, "pass")
    initial_pins_count = @other_member.pins.count

    post "/mobile/#{unsubscribed_item.id}/pin"

    assert_redirected_to '/mobile'
    assert_equal 'Access denied', flash[:alert]
    # Verify no pin was created
    assert_equal initial_pins_count, @other_member.pins.reload.count
  end

  # Positive tests - Authorized access
  test "read_feed allows access to own subscription" do
    login_as(@member, "mala")

    get "/mobile/#{@subscription.id}"

    assert_response :success
    assert_select 'body'
  end

  test "mark_as_read allows access to own subscription" do
    login_as(@member, "mala")
    @subscription.update!(has_unread: true)

    post "/mobile/#{@subscription.id}/read", params: { timestamp: Time.now.to_i }

    assert_redirected_to '/mobile'
    @subscription.reload
    assert_equal false, @subscription.has_unread
  end

  test "pin allows access to items from subscribed feeds" do
    login_as(@member, "mala")
    initial_pins_count = @member.pins.count

    post "/mobile/#{@item.id}/pin"

    assert_redirected_to "/mobile/#{@subscription.id}#item-#{@item.id}"
    assert_equal initial_pins_count + 1, @member.pins.reload.count
  end

  private

  def login_as(member, password)
    post session_url, params: { username: member.username, password: password }
    follow_redirect! if response.redirect?
  end
end
