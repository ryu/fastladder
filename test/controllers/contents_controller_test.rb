# frozen_string_literal: true

require "test_helper"

class ContentsControllerTest < ActionController::TestCase
  def setup
    @member = create_member(password: "password")
  end

  test "GET guide requires login" do
    get :guide
    assert_redirected_to "/login"
  end

  test "GET guide renders without layout when logged in" do
    get :guide, session: { member_id: @member.id }
    assert_response :success
    assert_template :guide
  end

  test "GET configure requires login" do
    get :configure
    assert_redirected_to "/login"
  end

  test "GET configure renders without layout when logged in" do
    get :configure, session: { member_id: @member.id }
    assert_response :success
    assert_template :configure
  end

  test "GET manage requires login" do
    get :manage
    assert_redirected_to "/login"
  end

  test "GET manage renders without layout when logged in" do
    get :manage, session: { member_id: @member.id }
    assert_response :success
    assert_template :manage
  end
end
