# frozen_string_literal: true

require "test_helper"

class Api::Feed::FaviconsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "test", password_confirmation: "test")
    @feed = create_feed(feedlink: "http://example.com/feed.xml")
  end

  test "POST /api/feed/fetch_favicon fetches favicon for valid feed" do
    Feed.stub :find_by, @feed do
      @feed.stub :fetch_favicon!, nil do
        post "/api/feed/fetch_favicon",
             params: { feedlink: @feed.feedlink },
             headers: { "HTTP_COOKIE" => login_cookie }
        assert_response :success
        json = response.parsed_body
        assert json["isSuccess"]
      end
    end
  end

  test "POST /api/feed/fetch_favicon fails without feedlink" do
    post "/api/feed/fetch_favicon",
         headers: { "HTTP_COOKIE" => login_cookie }
    assert_response :success
    json = response.parsed_body
    assert_not json["isSuccess"]
  end

  test "POST /api/feed/fetch_favicon fails for unknown feed" do
    post "/api/feed/fetch_favicon",
         params: { feedlink: "http://unknown.example.com/feed.xml" },
         headers: { "HTTP_COOKIE" => login_cookie }
    assert_response :success
    json = response.parsed_body
    assert_not json["isSuccess"]
  end

  test "POST /api/feed/fetch_favicon requires authentication" do
    post "/api/feed/fetch_favicon", params: { feedlink: @feed.feedlink }
    assert_predicate response.body, :blank?
  end

  private

  def login_cookie
    post "/session", params: {
      username: @member.username,
      password: "test"
    }
    response.headers["Set-Cookie"]
  end
end
