# frozen_string_literal: true

require "test_helper"

class AccountControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "password", password_confirmation: "password")
  end

  # Password page tests
  test "GET password requires login" do
    get "/account/password"
    assert_redirected_to "/login"
  end

  test "GET password renders form when logged in" do
    login_as(@member, password: "password")
    get "/account/password"
    assert_response :success
  end

  test "POST password with wrong current password shows error" do
    login_as(@member, password: "password")
    post "/account/password", params: {
      account: {
        password: "wrong_password",
        new_password: "newpass123",
        new_password_confirmation: "newpass123"
      }
    }
    assert_response :success
  end

  test "POST password with correct password updates password" do
    login_as(@member, password: "password")
    post "/account/password", params: {
      account: {
        password: "password",
        new_password: "newpass123",
        new_password_confirmation: "newpass123"
      }
    }
    assert_response :success
    @member.reload
    assert @member.authenticated?("newpass123")
  end

  test "POST password with mismatched confirmation shows error" do
    login_as(@member, password: "password")
    post "/account/password", params: {
      account: {
        password: "password",
        new_password: "newpass123",
        new_password_confirmation: "different"
      }
    }
    assert_response :success
  end

  # API key page tests
  test "GET apikey requires login" do
    get "/account/apikey"
    assert_redirected_to "/login"
  end

  test "GET apikey renders form when logged in" do
    login_as(@member, password: "password")
    get "/account/apikey"
    assert_response :success
  end

  test "POST apikey generates new auth key" do
    assert_nil @member.auth_key
    login_as(@member, password: "password")
    post "/account/apikey"
    assert_response :success
    @member.reload
    assert_not_nil @member.auth_key
    assert_predicate @member.auth_key.length, :positive?
  end

  test "POST apikey regenerates auth key" do
    @member.set_auth_key
    old_key = @member.auth_key
    login_as(@member, password: "password")
    post "/account/apikey"
    @member.reload
    assert_not_equal old_key, @member.auth_key
  end

  private

  def login_as(member, password:)
    post "/session", params: { username: member.username, password: password }
  end
end
