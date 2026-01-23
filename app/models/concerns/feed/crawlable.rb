# frozen_string_literal: true

module Feed::Crawlable
  extend ActiveSupport::Concern

  def crawl
    return unless can_crawl?

    with_crawl_lock do
      Fastladder::Crawler.new(logger).crawl(self)
    end
  end

  private

  def can_crawl?
    crawl_status.status == Fastladder::Crawler::CRAWL_OK
  end

  def with_crawl_lock
    crawl_status.update!(status: Fastladder::Crawler::CRAWL_NOW)
    yield
  rescue => e
    logger.error "Crawler error: #{e.message}"
  ensure
    crawl_status.update!(status: Fastladder::Crawler::CRAWL_OK)
  end
end
