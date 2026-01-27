# frozen_string_literal: true

require "test_helper"

class Utility::BookmarkletControllerTest < ActionController::TestCase
  test "GET index renders bookmarklet page" do
    get :index

    assert_response :success
    assert_select "h2", "Browser Buttons"
  end
end
