# frozen_string_literal: true

require "test_helper"

class ReaderControllerTest < ActionController::TestCase
  def setup
    @member = create_member(password: "password")
  end

  test "GET welcome requires login" do
    get :welcome
    assert_redirected_to "/login"
  end

  test "GET welcome redirects to index when logged in" do
    get :welcome, session: { member_id: @member.id }
    assert_redirected_to action: :index, trailing_slash: true
  end

  test "GET index requires login" do
    get :index
    assert_redirected_to "/login"
  end

  test "GET index renders without layout when logged in" do
    get :index, session: { member_id: @member.id }
    assert_response :success
    assert_template :index
  end
end
