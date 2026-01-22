# frozen_string_literal: true

require "test_helper"

class CrawlStatusIdempotencyTest < ActiveSupport::TestCase
  def setup
    @feed = create_feed_with_crawl_status
    @feed.subscribers_count = 1
    @feed.save!
  end

  test "fetch_crawlable_feed marks feed as CRAWL_NOW atomically" do
    # Set up a crawlable feed
    @feed.crawl_status.update!(
      status: Fastladder::Crawler::CRAWL_OK,
      crawled_on: 1.hour.ago
    )

    fetched_feed = CrawlStatus.fetch_crawlable_feed

    assert_equal @feed.id, fetched_feed.id
    assert_equal Fastladder::Crawler::CRAWL_NOW, fetched_feed.crawl_status.reload.status
  end

  test "fetch_crawlable_feed returns nil when no feeds are crawlable" do
    # Mark all feeds as currently being crawled (recently, so not reset as stale)
    CrawlStatus.update_all(status: Fastladder::Crawler::CRAWL_NOW, crawled_on: 1.minute.ago)

    assert_nil CrawlStatus.fetch_crawlable_feed
  end

  test "fetch_crawlable_feed resets stale crawls" do
    # Create a stale crawl (started 35 minutes ago but never finished)
    @feed.crawl_status.update!(
      status: Fastladder::Crawler::CRAWL_NOW,
      crawled_on: 35.minutes.ago
    )

    fetched_feed = CrawlStatus.fetch_crawlable_feed

    # The stale crawl should be reset and the feed should be fetched
    assert_equal @feed.id, fetched_feed.id
  end

  test "fetch_crawlable_feed uses atomic update with where clause" do
    # Set up a crawlable feed
    @feed.crawl_status.update!(
      status: Fastladder::Crawler::CRAWL_OK,
      crawled_on: 1.hour.ago
    )

    # The atomic update uses WHERE id=X AND status=CRAWL_OK
    # If another process changes status to CRAWL_NOW first,
    # the WHERE clause won't match and 0 rows will be affected.

    # We can verify this by:
    # 1. Finding what would be the candidate
    candidate = CrawlStatus
                .joins(:feed)
                .merge(CrawlStatus.status_ok)
                .merge(CrawlStatus.expired(Settings.crawl_interval.minutes))
                .merge(Feed.has_subscriptions)
                .order(:crawled_on)
                .first

    # 2. Simulating another crawler took it
    candidate.update!(status: Fastladder::Crawler::CRAWL_NOW, crawled_on: 1.minute.ago)

    # 3. Attempting to acquire it should fail (return nil with only one feed)
    result = CrawlStatus.fetch_crawlable_feed

    # Should return nil because the only candidate was already taken
    assert_nil result
  end

  test "fetch_crawlable_feed does not fetch recently crawled feeds" do
    # Mark feed as crawled very recently
    @feed.crawl_status.update!(
      status: Fastladder::Crawler::CRAWL_OK,
      crawled_on: 1.minute.ago
    )

    # Should not fetch because it was crawled too recently
    assert_nil CrawlStatus.fetch_crawlable_feed
  end
end
