# Helper methods for creating test data
# Use when fixtures aren't sufficient (e.g., need unique records)
module TestDataHelper
  @sequence = 0

  class << self
    attr_accessor :sequence
  end

  def next_sequence
    TestDataHelper.sequence += 1
  end

  def create_member(attrs = {})
    seq = next_sequence
    password = attrs.delete(:password) || "password"
    Member.create!({
      username: "user_#{seq}",
      email: "user_#{seq}@example.com",
      password: password,
      password_confirmation: password
    }.merge(attrs))
  end

  def create_feed(attrs = {})
    seq = next_sequence
    Feed.create!({
      feedlink: "http://test-feed-#{seq}.test/feed.xml",
      link: "http://test-feed-#{seq}.test/",
      title: "Feed #{seq}",
      description: "Description for feed #{seq}"
    }.merge(attrs))
  end

  def create_crawl_status(attrs = {})
    CrawlStatus.create!({
      status: Fastladder::Crawler::CRAWL_OK,
      error_count: 0
    }.merge(attrs))
  end

  def create_feed_with_crawl_status(feed_attrs = {}, crawl_attrs = {})
    feed = create_feed(feed_attrs)
    feed.create_crawl_status!({
      status: Fastladder::Crawler::CRAWL_OK,
      error_count: 0,
      crawled_on: 31.minutes.ago
    }.merge(crawl_attrs))
    feed
  end

  def create_item(attrs = {})
    seq = next_sequence
    feed = attrs.delete(:feed) || feeds(:feed_one)
    Item.create!({
      feed: feed,
      link: "http://example.com/article_#{seq}",
      title: "Article #{seq}",
      body: "Body of article #{seq}",
      author: "author",
      category: "category",
      guid: "guid_#{seq}",
      stored_on: Time.current,
      modified_on: Time.current,
      created_on: Time.current
    }.merge(attrs))
  end

  def create_subscription(attrs = {})
    member = attrs.delete(:member) || members(:member_one)
    feed = attrs.delete(:feed) || create_feed
    Subscription.create!({
      member: member,
      feed: feed,
      public: false
    }.merge(attrs))
  end

  def create_folder(attrs = {})
    seq = next_sequence
    member = attrs.delete(:member) || members(:member_one)
    Folder.create!({
      member: member,
      name: "Folder #{seq}"
    }.merge(attrs))
  end

  def create_pin(attrs = {})
    seq = next_sequence
    member = attrs.delete(:member) || members(:member_one)
    Pin.create!({
      member: member,
      link: "http://example.com/pin_#{seq}",
      title: "Pinned #{seq}"
    }.merge(attrs))
  end

  def build_item(attrs = {})
    seq = next_sequence
    feed = attrs.delete(:feed)
    Item.new({
      feed: feed,
      link: "http://example.com/article_#{seq}",
      title: "Article #{seq}",
      body: "Body of article #{seq}",
      author: "author",
      category: "category",
      guid: attrs[:guid] || "guid_#{seq}",
      stored_on: Time.current,
      modified_on: Time.current,
      created_on: Time.current
    }.merge(attrs))
  end

  def build_items(count, attrs = {})
    Array.new(count) { build_item(attrs) }
  end

  def build_item_with_fixed_guid(attrs = {})
    build_item(attrs.merge(guid: "fixed_guid", title: "Fixed Title", body: "Fixed Body"))
  end

  def create_item_with_fixed_guid(attrs = {})
    create_item(attrs.merge(guid: "fixed_guid", title: "Fixed Title", body: "Fixed Body"))
  end
end
