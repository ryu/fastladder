require "test_helper"

class MemberTest < ActiveSupport::TestCase
  test "authenticate with correct password" do
    member = create_member(username: "auth_test", password: "mala")
    assert Member.authenticate("auth_test", "mala")
  end

  test "authenticate with incorrect password" do
    member = create_member(username: "auth_test2", password: "mala")
    assert_nil Member.authenticate("auth_test2", "ssig33")
  end

  test "public_subscribe_count returns count of public subscriptions" do
    member = create_member
    create_subscription(member: member, feed: create_feed, public: true)
    create_subscription(member: member, feed: create_feed, public: false)
    create_subscription(member: member, feed: create_feed, public: false)
    assert_equal 1, member.public_subscribe_count
  end

  test "public_subs includes public subscription" do
    member = create_member
    public_subscription = create_subscription(member: member, feed: create_feed, public: true)
    non_public_subscription = create_subscription(member: member, feed: create_feed, public: false)
    assert_includes member.public_subs, public_subscription
    refute_includes member.public_subs, non_public_subscription
  end

  test "recent_subs returns correct number of subscriptions" do
    member = create_member
    sub_1 = create_subscription(member: member, feed: create_feed, created_on: 1.day.ago)
    sub_2 = create_subscription(member: member, feed: create_feed, created_on: 3.days.ago)
    sub_3 = create_subscription(member: member, feed: create_feed, created_on: 2.days.ago)
    sub_4 = create_subscription(member: member, feed: create_feed, created_on: 4.days.ago)
    assert_equal 3, member.recent_subs(3).size
  end

  test "recent_subs returns subscriptions in correct order" do
    member = create_member
    sub_1 = create_subscription(member: member, feed: create_feed, created_on: 1.day.ago)
    sub_2 = create_subscription(member: member, feed: create_feed, created_on: 3.days.ago)
    sub_3 = create_subscription(member: member, feed: create_feed, created_on: 2.days.ago)
    sub_4 = create_subscription(member: member, feed: create_feed, created_on: 4.days.ago)
    assert_equal [sub_1, sub_3, sub_2], member.recent_subs(3)
  end
end
