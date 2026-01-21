require "test_helper"

class CrawlStatusTest < ActiveSupport::TestCase
  test "belongs to feed" do
    feed = FactoryBot.create(:feed)
    crawl_status = FactoryBot.create(:crawl_status, feed: feed)
    assert_equal feed, crawl_status.feed
  end

  test "status_ok scope returns ok status" do
    ok_status = FactoryBot.create(:crawl_status, status: Fastladder::Crawler::CRAWL_OK)
    ng_status = FactoryBot.create(:crawl_status, status: Fastladder::Crawler::CRAWL_NOW)
    assert_includes CrawlStatus.status_ok, ok_status
    refute_includes CrawlStatus.status_ok, ng_status
  end

  test "expired scope returns null crawled_on" do
    expired = FactoryBot.create(:crawl_status, crawled_on: nil)
    not_expired = FactoryBot.create(:crawl_status, crawled_on: Time.current)
    assert_includes CrawlStatus.expired(30.minutes), expired
    refute_includes CrawlStatus.expired(30.minutes), not_expired
  end

  test "expired scope returns old crawled_on" do
    expired = FactoryBot.create(:crawl_status, crawled_on: 31.minutes.ago)
    not_expired = FactoryBot.create(:crawl_status, crawled_on: 29.minutes.ago)
    assert_includes CrawlStatus.expired(30.minutes), expired
    refute_includes CrawlStatus.expired(30.minutes), not_expired
  end

  test "fetch_crawlable_feed returns feed with ok status" do
    feed = FactoryBot.create(:crawl_ok_feed, crawl_status: FactoryBot.create(:crawl_status, crawled_on: 31.minutes.ago))
    result = CrawlStatus.fetch_crawlable_feed
    assert_equal feed, result
  end

  test "fetch_crawlable_feed updates status to CRAWL_NOW" do
    feed = FactoryBot.create(:crawl_ok_feed, crawl_status: FactoryBot.create(:crawl_status, crawled_on: 31.minutes.ago))
    CrawlStatus.fetch_crawlable_feed
    feed.reload
    assert_equal Fastladder::Crawler::CRAWL_NOW, feed.crawl_status.status
  end

  test "fetch_crawlable_feed returns nil when no crawlable feed" do
    FactoryBot.create(:crawl_ok_feed, crawl_status: FactoryBot.create(:crawl_status, crawled_on: 10.minutes.ago))
    result = CrawlStatus.fetch_crawlable_feed
    assert_nil result
  end

  test "fetch_crawlable_feed resets stuck feeds" do
    feed = FactoryBot.create(:crawl_ok_feed, crawl_status: FactoryBot.create(:crawl_status, status: Fastladder::Crawler::CRAWL_NOW, crawled_on: 31.minutes.ago))
    CrawlStatus.fetch_crawlable_feed
    feed.reload
    assert_equal Fastladder::Crawler::CRAWL_NOW, feed.crawl_status.status
  end
end
