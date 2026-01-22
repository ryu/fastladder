# == Schema Information
#
# Table name: crawl_statuses
#
#  id               :integer          not null, primary key
#  feed_id          :integer          default(0), not null
#  status           :integer          default(1), not null
#  error_count      :integer          default(0), not null
#  error_message    :string(255)
#  http_status      :integer
#  digest           :string(255)
#  update_frequency :integer          default(0), not null
#  crawled_on       :datetime
#  created_on       :datetime         not null
#  updated_on       :datetime         not null
#

class CrawlStatus < ActiveRecord::Base
  belongs_to :feed, optional: true

  scope :status_ok, ->{ where(status: Fastladder::Crawler::CRAWL_OK) }
  scope :expired, ->(ttl){ where("crawled_on IS NULL OR crawled_on < ?", ttl.ago) }

  # Fetches a crawlable feed with atomic locking to prevent concurrent crawls.
  #
  # Uses optimistic locking pattern for SQLite compatibility:
  # 1. Find a candidate feed with status CRAWL_OK
  # 2. Atomically try to update status to CRAWL_NOW
  # 3. If update succeeds (affected 1 row), we acquired the lock
  # 4. If update fails (affected 0 rows), another crawler got it - retry
  #
  # @param options [Hash] Options (currently unused, reserved for future)
  # @param max_retries [Integer] Maximum retries to find available feed (default: 5)
  # @return [Feed, nil] The feed to crawl, or nil if none available
  def self.fetch_crawlable_feed(options = {}, max_retries: 5)
    # Reset stale crawls (crawls that started but never finished)
    CrawlStatus.where("crawled_on < ?", 30.minutes.ago)
               .where(status: Fastladder::Crawler::CRAWL_NOW)
               .update_all(status: Fastladder::Crawler::CRAWL_OK)

    retries = 0
    loop do
      # Find candidate feed
      candidate = CrawlStatus
                  .joins(:feed)
                  .merge(CrawlStatus.status_ok)
                  .merge(CrawlStatus.expired(Settings.crawl_interval.minutes))
                  .merge(Feed.has_subscriptions)
                  .order(:crawled_on)
                  .first

      return nil unless candidate

      # Atomic update - only succeeds if status is still CRAWL_OK
      updated_count = CrawlStatus
                      .where(id: candidate.id, status: Fastladder::Crawler::CRAWL_OK)
                      .update_all(status: Fastladder::Crawler::CRAWL_NOW, crawled_on: Time.now)

      return candidate.feed if updated_count.positive?

      # We acquired the lock successfully

      # Another crawler got this feed, retry with a different one
      retries += 1
      return nil if retries >= max_retries
    end
  end
end
