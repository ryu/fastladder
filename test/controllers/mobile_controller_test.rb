require "test_helper"

class MobileControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = FactoryBot.create(:member, password: "pass", password_confirmation: "pass")
    @other_member = FactoryBot.create(:member, username: "other_user", email: "other@example.com", password: "pass", password_confirmation: "pass")
    @feed = FactoryBot.create(:feed)
    @item = FactoryBot.create(:item, feed: @feed)
    @subscription = FactoryBot.create(:subscription, feed: @feed, member: @member)
    @other_subscription = FactoryBot.create(:subscription, feed: @feed, member: @other_member)
  end

  # Security tests - Unauthorized access prevention
  test "read_feed prevents access to other user's subscription" do
    login_as(@other_member)

    get "/mobile/#{@subscription.id}"

    assert_response :not_found
  end

  test "mark_as_read prevents access to other user's subscription" do
    login_as(@other_member)
    @subscription.update!(has_unread: true)
    original_viewed_on = @subscription.viewed_on

    get "/mobile/#{@subscription.id}/read", params: { timestamp: Time.now.to_i }

    assert_response :not_found
    # Verify subscription was not modified
    @subscription.reload
    assert_equal true, @subscription.has_unread, "has_unread should not have been modified"
    assert_equal original_viewed_on, @subscription.viewed_on, "viewed_on should not have been modified"
  end

  test "pin prevents access to items from unsubscribed feeds" do
    # Create a feed that only @member is subscribed to
    unsubscribed_feed = FactoryBot.create(:feed, feedlink: "http://example.com/unsubscribed")
    unsubscribed_item = FactoryBot.create(:item, feed: unsubscribed_feed)
    FactoryBot.create(:subscription, feed: unsubscribed_feed, member: @member)

    login_as(@other_member)
    initial_pins_count = @other_member.pins.count

    get "/mobile/#{unsubscribed_item.id}/pin"

    assert_redirected_to '/mobile'
    assert_equal 'Access denied', flash[:alert]
    # Verify no pin was created
    assert_equal initial_pins_count, @other_member.pins.reload.count
  end

  # Positive tests - Authorized access
  test "read_feed allows access to own subscription" do
    login_as(@member)

    get "/mobile/#{@subscription.id}"

    assert_response :success
    assert_select 'body'
  end

  test "mark_as_read allows access to own subscription" do
    login_as(@member)
    @subscription.update!(has_unread: true)

    get "/mobile/#{@subscription.id}/read", params: { timestamp: Time.now.to_i }

    assert_redirected_to '/mobile'
    @subscription.reload
    assert_equal false, @subscription.has_unread
  end

  test "pin allows access to items from subscribed feeds" do
    login_as(@member)
    initial_pins_count = @member.pins.count

    get "/mobile/#{@item.id}/pin"

    assert_redirected_to "/mobile/#{@subscription.id}#item-#{@item.id}"
    assert_equal initial_pins_count + 1, @member.pins.reload.count
  end

  private

  def login_as(member)
    post session_url, params: { username: member.username, password: 'pass' }
    follow_redirect! if response.redirect?
  end
end
