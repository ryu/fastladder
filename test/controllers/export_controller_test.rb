# frozen_string_literal: true

require "test_helper"

class ExportControllerTest < ActionDispatch::IntegrationTest
  def setup
    @member = create_member(password: "password", password_confirmation: "password")
    @feed = create_feed(
      title: "Test Feed",
      link: "http://example.com/",
      feedlink: "http://example.com/feed.xml"
    )
    @subscription = create_subscription(member: @member, feed: @feed)
  end

  test "GET opml requires login" do
    get "/export/opml"
    assert_redirected_to "/login"
  end

  test "GET opml returns XML content type" do
    login_as(@member, password: "password")
    get "/export/opml"
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
  end

  test "GET opml returns valid OPML structure" do
    login_as(@member, password: "password")
    get "/export/opml"
    assert_response :success

    xml = response.body
    assert_includes xml, '<?xml version="1.0"'
    assert_includes xml, "<opml"
    assert_includes xml, "<head>"
    assert_includes xml, "<body>"
  end

  test "GET opml includes subscribed feeds" do
    login_as(@member, password: "password")
    get "/export/opml"
    assert_response :success

    xml = response.body
    assert_includes xml, "Test Feed"
    assert_includes xml, "http://example.com/feed.xml"
  end

  test "GET opml organizes feeds by folder" do
    folder = create_folder(member: @member, name: "Tech")
    @subscription.update!(folder: folder)

    login_as(@member, password: "password")
    get "/export/opml"
    assert_response :success

    xml = response.body
    assert_includes xml, 'text="Tech"'
  end

  test "GET opml handles feeds without folder" do
    login_as(@member, password: "password")
    get "/export/opml"
    assert_response :success
    # Feed without folder should still be included
    assert_includes response.body, "Test Feed"
  end

  test "GET opml with no subscriptions returns empty OPML" do
    @subscription.destroy

    login_as(@member, password: "password")
    get "/export/opml"
    assert_response :success

    xml = response.body
    assert_includes xml, "<opml"
    assert_includes xml, "<body>"
  end

  private

  def login_as(member, password:)
    post "/session", params: { username: member.username, password: password }
  end
end
