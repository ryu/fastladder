require "test_helper"

class MemberSaveValidationTest < ActiveSupport::TestCase
  test "remember_me_until saves without validation even if username is empty" do
    # Create a valid member first
    member = create_member

    # Manually clear username to violate validates_presence_of :username
    member.username = ""

    # save(validate: false) should succeed even with invalid username
    time = 2.weeks.from_now.utc
    assert member.remember_me_until(time)

    member.reload
    assert member.remember_token.present?
  end

  test "forget_me saves without validation even if username is empty" do
    # Create a valid member first
    member = create_member

    # Set a remember token first
    member.remember_me_until(2.weeks.from_now.utc)

    # Manually clear username to violate validates_presence_of :username
    member.username = ""

    # save(validate: false) should succeed even with invalid username
    assert member.forget_me

    member.reload
    assert member.remember_token.nil?
    assert member.remember_token_expires_at.nil?
  end

  test "validate: false skips validation correctly" do
    member = create_member

    # These should NOT raise validation errors
    assert_nothing_raised do
      member.remember_me_until(2.weeks.from_now.utc)
    end

    assert_nothing_raised do
      member.forget_me
    end
  end
end
