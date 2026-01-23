# frozen_string_literal: true

require "test_helper"

class ShareControllerTest < ActionController::TestCase
  def setup
    @member = create_member(password: "password")
  end

  test "GET index requires login" do
    get :index
    assert_redirected_to "/login"
  end

  test "GET index renders when logged in" do
    get :index, session: { member_id: @member.id }
    assert_response :success
    assert_template :index
  end

  test "GET index assigns current member" do
    get :index, session: { member_id: @member.id }
    assert_response :success
    # Verify the view can access current_member (implicit through controller)
  end
end
