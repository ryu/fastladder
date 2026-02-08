require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  test "creation updates subscribers count" do
    feed = create_feed
    original_count = feed.subscribers_count

    subscription = Subscription.new
    subscription.feed = feed
    subscription.member = create_member
    subscription.save

    feed.reload
    assert_equal original_count + 1, feed.subscribers_count
  end

  test "creation sets default public value" do
    feed = create_feed
    member = create_member

    subscription = Subscription.new
    subscription.feed = feed
    subscription.member = member
    subscription.public = nil
    subscription.save

    assert_equal false, subscription.public
  end

  test "destroy updates subscribers count" do
    subscription = create_subscription
    feed = subscription.feed
    original_count = feed.subscribers_count

    subscription.destroy

    feed.reload
    assert_equal original_count - 1, feed.subscribers_count
  end
end
