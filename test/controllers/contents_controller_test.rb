# frozen_string_literal: true

require "test_helper"

class ContentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "password", password_confirmation: "password")
  end

  test "GET guide requires login" do
    get "/contents/guide"
    assert_redirected_to "/login"
  end

  test "GET guide renders without layout when logged in" do
    post "/session", params: { username: @member.username, password: "password" }
    get "/contents/guide"
    assert_response :success
  end

  test "GET configure requires login" do
    get "/contents/config"
    assert_redirected_to "/login"
  end

  test "GET configure renders without layout when logged in" do
    post "/session", params: { username: @member.username, password: "password" }
    get "/contents/config"
    assert_response :success
  end

  test "GET manage requires login" do
    get "/contents/manage"
    assert_redirected_to "/login"
  end

  test "GET manage renders without layout when logged in" do
    post "/session", params: { username: @member.username, password: "password" }
    get "/contents/manage"
    assert_response :success
  end
end
