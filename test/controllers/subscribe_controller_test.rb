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

  test "POST subscribe with check_for_subscribe creates subscription and redirects" do
    feed_url = "http://example.com/feed.xml"
    stub_request(:get, feed_url)
      .to_return(status: 200, body: sample_rss_feed, headers: { "Content-Type" => "application/rss+xml" })

    assert_difference "@member.subscriptions.count", 1 do
      post :subscribe,
           params: {
             url: "http://example.com",
             check_for_subscribe: [feed_url],
             public: "1",
             rate: "3"
           },
           session: { member_id: @member.id }
    end

    assert_redirected_to controller: "reader"
    subscription = @member.subscriptions.last

    assert_equal 3, subscription.rate
  end

  test "POST subscribe with folder_id creates subscription in folder" do
    folder = create_folder(member: @member, name: "Tech")
    feed_url = "http://example.com/feed.xml"
    stub_request(:get, feed_url)
      .to_return(status: 200, body: sample_rss_feed, headers: { "Content-Type" => "application/rss+xml" })

    post :subscribe,
         params: {
           url: "http://example.com",
           check_for_subscribe: [feed_url],
           folder_id: folder.id.to_s
         },
         session: { member_id: @member.id }

    subscription = @member.subscriptions.last

    assert_equal folder.id, subscription.folder_id
  end

  test "POST subscribe with zero folder_id sets folder_id to nil" do
    feed_url = "http://example.com/feed.xml"
    stub_request(:get, feed_url)
      .to_return(status: 200, body: sample_rss_feed, headers: { "Content-Type" => "application/rss+xml" })

    post :subscribe,
         params: {
           url: "http://example.com",
           check_for_subscribe: [feed_url],
           folder_id: "0"
         },
         session: { member_id: @member.id }

    subscription = @member.subscriptions.last

    assert_nil subscription.folder_id
  end

  private

  def sample_rss_feed
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Example Feed</title>
          <link>http://example.com</link>
          <description>An example feed</description>
          <item>
            <title>Test Item</title>
            <link>http://example.com/item1</link>
            <description>Test content</description>
          </item>
        </channel>
      </rss>
    XML
  end
end
