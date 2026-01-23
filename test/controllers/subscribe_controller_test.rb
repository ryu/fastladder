# frozen_string_literal: true

require "test_helper"

class SubscribeControllerTest < ActionController::TestCase
  def setup
    @member = create_member(password: "password")
  end

  # Index tests
  test "GET index requires login" do
    get :index

    assert_redirected_to "/login"
  end

  test "GET index renders when logged in" do
    get :index, session: { member_id: @member.id }

    assert_response :success
    assert_template :index
  end

  test "GET index with url param redirects to confirm" do
    FeedSearcher.stub :search, [] do
      get :index, params: { url: "http://example.com" }, session: { member_id: @member.id }

      assert_redirected_to action: "index"
    end
  end

  # Confirm tests
  test "GET confirm searches url by FeedSearcher" do
    FeedSearcher.stub :search, [] do
      get :confirm, params: { url: "http://example.com" }, session: { member_id: @member.id }

      assert_response :redirect
    end
  end

  test "GET confirm with no feeds found shows flash and redirects" do
    FeedSearcher.stub :search, [] do
      get :confirm, params: { url: "http://example.com" }, session: { member_id: @member.id }

      assert_redirected_to action: "index"
      assert_equal "please check URL", flash[:notice]
    end
  end

  test "GET confirm with feeds found renders confirm template" do
    feed_url = "http://example.com/feed.xml"
    Feed.stub :initialize_from_uri, Feed.new(feedlink: feed_url, title: "Test", link: "http://example.com") do
      FeedSearcher.stub :search, [feed_url] do
        get :confirm, params: { url: "http://example.com" }, session: { member_id: @member.id }

        assert_response :success
        assert_template :confirm
        assert_not_empty assigns(:feeds)
      end
    end
  end

  test "GET confirm with existing feed shows subscription status" do
    feed = create_feed(feedlink: "http://example.com/feed.xml")
    subscription = create_subscription(member: @member, feed: feed)

    FeedSearcher.stub :search, [feed.feedlink] do
      get :confirm, params: { url: "http://example.com" }, session: { member_id: @member.id }

      assert_response :success
      assert_equal subscription.id, assigns(:feeds).first.subscribe_id
    end
  end

  # Subscribe action tests
  # Note: Subscribe route uses splat (*url), tested in integration tests
  # Here we test the controller action with ActionController::TestCase style
  test "POST subscribe without check_for_subscribe redirects with notice" do
    # Match splat route pattern
    @request.path = "/subscribe/http://example.com"
    post :subscribe, params: { url: "http://example.com" }, session: { member_id: @member.id }

    assert_redirected_to action: "confirm", url: "http://example.com"
    assert_equal "please check for subscribe", flash[:notice]
  end
end
