# frozen_string_literal: true

require "test_helper"

class AccountControllerTest < ActionController::TestCase
  def setup
    @member = create_member(password: "password")
  end

  # Password page tests
  test "GET password requires login" do
    get :password
    assert_redirected_to "/login"
  end

  test "GET password renders form when logged in" do
    get :password, session: { member_id: @member.id }
    assert_response :success
    assert_template :password
  end

  test "POST password with wrong current password shows error" do
    post :password, params: {
      account: {
        password: "wrong_password",
        new_password: "newpass123",
        new_password_confirmation: "newpass123"
      }
    }, session: { member_id: @member.id }

    assert_response :success
    assert assigns(:member).errors[:password].any?
  end

  test "POST password with correct password updates password" do
    post :password, params: {
      account: {
        password: "password",
        new_password: "newpass123",
        new_password_confirmation: "newpass123"
      }
    }, session: { member_id: @member.id }

    assert_response :success
    @member.reload
    assert @member.authenticated?("newpass123")
  end

  test "POST password with mismatched confirmation shows error" do
    post :password, params: {
      account: {
        password: "password",
        new_password: "newpass123",
        new_password_confirmation: "different"
      }
    }, session: { member_id: @member.id }

    assert_response :success
    assert assigns(:member).errors[:password_confirmation].any?
  end

  # API key page tests
  test "GET apikey requires login" do
    get :apikey
    assert_redirected_to "/login"
  end

  test "GET apikey renders form when logged in" do
    get :apikey, session: { member_id: @member.id }
    assert_response :success
    assert_template :apikey
  end

  test "POST apikey generates new auth key" do
    assert_nil @member.auth_key

    post :apikey, session: { member_id: @member.id }

    assert_response :success
    @member.reload
    assert_not_nil @member.auth_key
    assert @member.auth_key.length > 0
  end

  test "POST apikey regenerates auth key" do
    @member.set_auth_key
    old_key = @member.auth_key

    post :apikey, session: { member_id: @member.id }

    @member.reload
    assert_not_equal old_key, @member.auth_key
  end
end
