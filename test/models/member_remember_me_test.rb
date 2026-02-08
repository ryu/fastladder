require "test_helper"

class MemberRememberMeTest < ActiveSupport::TestCase
  test "remember_me_until sets remember_token and expiration" do
    member = create_member
    time = 2.weeks.from_now.utc

    member.remember_me_until(time)
    member.reload

    assert member.remember_token.present?
    assert member.remember_token_expires_at.present?
    assert_equal time.to_i, member.remember_token_expires_at.to_i
  end

  test "forget_me clears remember_token and expiration" do
    member = create_member
    time = 2.weeks.from_now.utc
    member.remember_me_until(time)
    member.reload
    assert member.remember_token.present?

    member.forget_me
    member.reload

    assert member.remember_token.nil?
    assert member.remember_token_expires_at.nil?
  end

  test "remember_me calls remember_me_for with 2 weeks" do
    member = create_member

    member.remember_me
    member.reload

    assert member.remember_token.present?
    assert member.remember_token_expires_at.present?
  end

  test "remember_token? returns true when token not expired" do
    member = create_member
    member.remember_me

    assert member.remember_token?
  end

  test "remember_token? returns false when token expired" do
    member = create_member
    member.remember_token_expires_at = 1.day.ago
    member.remember_token = "test_token"
    member.save

    refute member.remember_token?
  end
end
