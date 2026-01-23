require "test_helper"

class ApiControllerTest < ActionController::TestCase
  def setup
    @member = create_member
    @feed = create_feed
    @item = create_item(feed: @feed)
    @subscription = create_subscription(feed: @feed, member: @member)
    @crawl_status = create_crawl_status(feed: @feed)
  end

  test "GET all renders json" do
    @items = Array.new(3) { create_item(feed: @feed) }

    get :all, params: { subscribe_id: @subscription.id }, session: { member_id: @member.id }

    assert JSON.parse(response.body)
  end

  test "GET all limit works" do
    @items = Array.new(3) { create_item(feed: @feed) }

    get :all, params: { subscribe_id: @subscription.id, limit: 2 }, session: { member_id: @member.id }

    assert_equal 2, JSON.parse(response.body)["items"].size
  end

  test "GET all offset works" do
    @items = Array.new(3) { create_item(feed: @feed) }

    get :all, params: { subscribe_id: @subscription.id, offset: 1 }, session: { member_id: @member.id }

    parsed = JSON.parse(response.body)

    assert_equal 3, parsed["items"].size
    item_ids = parsed["items"].map { |item| item["id"] }

    assert_equal [@item.id].concat(@items.map(&:id)).sort.slice(0, 3), item_ids.sort
  end

  test "GET all renders purified link" do
    feed = create_feed
    create_item(feed: feed, link: "http://www.example.com/get?x=1&y=2")
    subscription = create_subscription(feed: feed, member: @member)

    get :all, params: { subscribe_id: subscription.id }, session: { member_id: @member.id }

    assert_includes JSON.parse(response.body)["items"].first["link"], "&amp;"
  end

  test "POST touch_all renders json" do
    post :touch_all, params: { subscribe_id: @subscription.id }, session: { member_id: @member.id }

    assert JSON.parse(response.body)
  end

  test "POST touch_all renders error" do
    post :touch_all, session: { member_id: @member.id }

    parsed = JSON.parse(response.body)

    assert_equal false, parsed["isSuccess"]
  end

  test "POST touch renders json" do
    post :touch, params: { timestamp: Time.now.to_i, subscribe_id: @subscription.id }, session: { member_id: @member.id }

    assert JSON.parse(response.body)
  end

  test "POST touch renders error" do
    post :touch, session: { member_id: @member.id }

    assert JSON.parse(response.body)
  end

  test "POST crawl renders json" do
    headers = {
      "Accept" => "text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "User-Agent" => "Fastladder FeedFetcher/0.0.3 (http://fastladder.org/)"
    }

    stub_request(:get, @feed.feedlink).with do |request|
      request.headers = headers
    end.to_return(status: 200, body: "", headers: {})

    post :crawl, params: { subscribe_id: @subscription.id }, session: { member_id: @member.id }

    assert JSON.parse(response.body)
  end

  test "GET subs has read and unread subscriptions" do
    unread_feed = create_feed
    create_item(feed: unread_feed, stored_on: 1.hour.ago)
    @unread_subscription = create_subscription(feed: unread_feed, member: @member, has_unread: true, viewed_on: 2.hours.ago)

    get :subs, session: { member_id: @member.id }

    assert_equal 2, JSON.parse(response.body).count
  end

  test "GET subs with unread has only unread subscriptions" do
    unread_feed = create_feed
    create_item(feed: unread_feed, stored_on: 1.hour.ago)
    @unread_subscription = create_subscription(feed: unread_feed, member: @member, has_unread: true, viewed_on: 2.hours.ago)

    get :subs, params: { unread: 1 }, session: { member_id: @member.id }

    assert_equal 1, JSON.parse(response.body).count
  end

  test "GET lite_subs renders json" do
    get :lite_subs, session: { member_id: @member.id }

    assert JSON.parse(response.body)
  end

  test "GET item_count renders json" do
    get :item_count, params: { since: @item.stored_on - 1.second }, session: { member_id: @member.id }

    assert_equal 1, response.body.to_i
  end

  test "GET item_count renders error" do
    get :item_count, session: { member_id: @member.id }

    parsed = JSON.parse(response.body)

    assert_equal false, parsed["isSuccess"]
  end

  test "GET unread_count renders json" do
    get :unread_count, params: { since: @item.stored_on }, session: { member_id: @member.id }

    assert_equal 0, response.body.to_i
  end

  test "GET unread_count renders error" do
    get :unread_count, session: { member_id: @member.id }

    parsed = JSON.parse(response.body)

    assert_equal false, parsed["isSuccess"]
  end

  test "not logged in renders blank" do
    get :subs

    assert_predicate response.body, :blank?
  end
end
