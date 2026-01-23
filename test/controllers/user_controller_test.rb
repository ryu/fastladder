# frozen_string_literal: true

require "test_helper"

class UserControllerTest < ActionController::TestCase
  def setup
    @member = create_member
    @member.update!(public: true)
    @feed = create_feed(title: "Public Feed")
    @subscription = create_subscription(member: @member, feed: @feed, public: true)
  end

  # HTML format tests
  test "GET index renders the index template" do
    get :index, params: { login_name: @member.username }

    assert_response :success
    assert_template "index"
  end

  test "GET index assigns target_member" do
    get :index, params: { login_name: @member.username }

    assert_response :success
    assert_equal @member, assigns(:target_member)
  end

  test "GET index assigns public subscriptions when member is public" do
    get :index, params: { login_name: @member.username }

    assert_response :success
    assert_not_nil assigns(:subscriptions)
    assert_includes assigns(:subscriptions), @subscription
  end

  test "GET index excludes private subscriptions" do
    private_sub = create_subscription(member: @member, public: false)

    get :index, params: { login_name: @member.username }

    assert_response :success
    assert_not_includes assigns(:subscriptions), private_sub
  end

  test "GET index does not assign subscriptions when member is not public" do
    @member.update!(public: false)

    get :index, params: { login_name: @member.username }

    assert_response :success
    assert_nil assigns(:subscriptions)
  end

  # RSS format tests
  test "GET index as RSS returns RSS content" do
    get :index, params: { login_name: @member.username, format: :rss }

    assert_response :success
    assert_includes response.content_type, "application/rss+xml"
  end

  test "GET index as RSS includes feed information" do
    get :index, params: { login_name: @member.username, format: :rss }

    assert_response :success
    assert_includes response.body, "Public Feed"
  end

  # OPML format tests
  test "GET index as OPML returns OPML content" do
    get :index, params: { login_name: @member.username, format: :opml }

    assert_response :success
    assert_equal "text/x-opml; charset=utf-8", response.content_type
  end

  test "GET index as OPML includes feed information" do
    get :index, params: { login_name: @member.username, format: :opml }

    assert_response :success
    assert_includes response.body, "<opml"
  end

  # Edge cases
  test "GET index limits subscriptions to 30" do
    # Create 35 subscriptions
    35.times do
      feed = create_feed
      create_subscription(member: @member, feed: feed, public: true)
    end

    get :index, params: { login_name: @member.username }

    assert_response :success
    assert_equal 30, assigns(:subscriptions).size
  end
end
