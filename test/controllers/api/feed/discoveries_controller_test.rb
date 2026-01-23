# frozen_string_literal: true

require "test_helper"

class Api::Feed::DiscoveriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "test", password_confirmation: "test")
    @feed = create_feed(feedlink: "http://example.com/feed.xml")
  end

  test "POST /api/feed/discover finds existing feed" do
    stub_request(:any, "http://example.com/feed.xml")
      .to_return(status: 200, body: "", headers: { "Content-Type" => "text/html" })

    post "/api/feed/discover",
         params: { url: @feed.feedlink },
         headers: { "HTTP_COOKIE" => login_cookie }
    assert_response :success
    json = response.parsed_body
    assert_kind_of Array, json
  end

  test "GET /api/feed/discover works with GET method" do
    stub_request(:any, "http://example.com/feed.xml")
      .to_return(status: 200, body: "", headers: { "Content-Type" => "text/html" })

    get "/api/feed/discover",
        params: { url: @feed.feedlink },
        headers: { "HTTP_COOKIE" => login_cookie }
    assert_response :success
    json = response.parsed_body
    assert_kind_of Array, json
  end

  test "POST /api/feed/discover requires authentication" do
    post "/api/feed/discover", params: { url: @feed.feedlink }
    # Without login, should return blank (login_required_api behavior)
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
