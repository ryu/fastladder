# frozen_string_literal: true

require "test_helper"

class ReaderControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "password", password_confirmation: "password")
  end

  test "GET welcome requires login" do
    get "/"
    assert_redirected_to "/login"
  end

  test "GET welcome redirects to reader when logged in" do
    login_as(@member, password: "password")
    get "/"
    assert_redirected_to "/reader/"
  end

  test "GET index requires login" do
    get "/reader"
    assert_redirected_to "/login"
  end

  test "GET index renders when logged in" do
    login_as(@member, password: "password")
    get "/reader"
    assert_response :success
  end

  private

  def login_as(member, password:)
    post "/session", params: { username: member.username, password: password }
  end
end
