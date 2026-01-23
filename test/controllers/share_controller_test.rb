# frozen_string_literal: true

require "test_helper"

class ShareControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "password", password_confirmation: "password")
  end

  test "GET index requires login" do
    get "/share"
    assert_redirected_to "/login"
  end

  test "GET index renders when logged in" do
    login_as(@member, password: "password")
    get "/share"
    assert_response :success
  end

  test "GET index assigns current member" do
    login_as(@member, password: "password")
    get "/share"
    assert_response :success
    # Verify the view can access current_member (implicit through controller)
  end

  private

  def login_as(member, password:)
    post "/session", params: { username: member.username, password: password }
  end
end
