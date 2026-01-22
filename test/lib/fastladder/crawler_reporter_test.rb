# frozen_string_literal: true

require "test_helper"

class Fastladder::CrawlerReporterTest < ActiveSupport::TestCase
  def setup
    @log_output = StringIO.new
    @logger = Logger.new(@log_output)
    @logger.level = Logger::DEBUG
    @reporter = Fastladder::CrawlerReporter.new(logger: @logger)
    @feed = create_feed
  end

  # === Crawl Lifecycle ===

  test "crawl_started increments counter and logs" do
    @reporter.crawl_started(@feed)

    assert_equal 1, @reporter.metrics[:crawls_started]
    assert_log_contains "crawl_started"
    assert_log_contains @feed.feedlink
  end

  test "crawl_completed increments counters and logs" do
    result = { new_items: 5, updated_items: 3, message: "5 new, 3 updated" }
    @reporter.crawl_completed(@feed, result)

    assert_equal 1, @reporter.metrics[:crawls_completed]
    assert_equal 5, @reporter.metrics[:items_new]
    assert_equal 3, @reporter.metrics[:items_updated]
    assert_log_contains "crawl_completed"
  end

  test "crawl_failed increments counters and categorizes error" do
    @reporter.crawl_failed(@feed, Timeout::Error.new("connection timed out"))

    assert_equal 1, @reporter.metrics[:crawls_failed]
    assert_equal 1, @reporter.metrics[:errors_transient]
    assert_log_contains "crawl_failed"
  end

  test "crawl_failed categorizes permanent errors" do
    @reporter.crawl_failed(@feed, "Cannot parse feed", category: :permanent)

    assert_equal 1, @reporter.metrics[:errors_permanent]
  end

  test "crawl_skipped increments counter and logs reason" do
    @reporter.crawl_skipped(@feed, "not_modified")

    assert_equal 1, @reporter.metrics[:crawls_skipped]
    assert_log_contains "crawl_skipped"
    assert_log_contains "not_modified"
  end

  # === Fetch Events ===

  test "fetch_completed logs success" do
    result = mock_fetch_result(success: true, status_code: 200, attempts: 1)
    @reporter.fetch_completed("https://example.com/feed.xml", result)

    assert_equal 1, @reporter.metrics[:fetches_success]
    assert_log_contains "fetch_completed"
  end

  test "fetch_completed logs not_modified" do
    result = mock_fetch_result(not_modified: true, status_code: 304)
    @reporter.fetch_completed("https://example.com/feed.xml", result)

    assert_equal 1, @reporter.metrics[:fetches_not_modified]
    assert_log_contains "fetch_not_modified"
  end

  test "fetch_completed logs redirect" do
    result = mock_fetch_result(redirect: true, status_code: 301, redirect_url: "https://new.example.com/")
    @reporter.fetch_completed("https://example.com/feed.xml", result)

    assert_equal 1, @reporter.metrics[:fetches_redirect]
    assert_log_contains "fetch_redirect"
  end

  test "fetch_completed logs failure" do
    result = mock_fetch_result(error: true, status_code: 500, error_message: "Internal Server Error")
    @reporter.fetch_completed("https://example.com/feed.xml", result)

    assert_equal 1, @reporter.metrics[:fetches_failed]
    assert_log_contains "fetch_failed"
  end

  # === Parse Events ===

  test "parse_completed logs success" do
    result = mock_parse_result(success: true, item_count: 10)
    @reporter.parse_completed("https://example.com/feed.xml", result)

    assert_equal 1, @reporter.metrics[:parses_success]
    assert_equal 10, @reporter.metrics[:items_parsed]
    assert_log_contains "parse_completed"
  end

  test "parse_completed logs failure" do
    result = mock_parse_result(success: false, error: "Invalid XML")
    @reporter.parse_completed("https://example.com/feed.xml", result)

    assert_equal 1, @reporter.metrics[:parses_failed]
    assert_log_contains "parse_failed"
  end

  # === Item Events ===

  test "items_persisted logs counts" do
    @reporter.items_persisted(@feed, 5, 2)

    assert_log_contains "items_persisted"
    assert_log_contains "new_items"
  end

  test "items_deleted logs count and reason" do
    @reporter.items_deleted(@feed, 100, reason: "too_many_new_items")

    assert_equal 100, @reporter.metrics[:items_deleted]
    assert_log_contains "items_deleted"
    assert_log_contains "too_many_new_items"
  end

  test "items_truncated logs original and limit" do
    @reporter.items_truncated(@feed, 1000, 500)

    assert_log_contains "items_truncated"
    assert_log_contains "1000"
    assert_log_contains "500"
  end

  # === System Events ===

  test "crawler_started resets metrics" do
    @reporter.crawl_started(@feed)
    @reporter.crawler_started

    assert_equal 0, @reporter.metrics[:crawls_started]
    assert_log_contains "crawler_started"
  end

  test "crawler_stopped logs elapsed time and metrics" do
    @reporter.crawler_stopped(reason: "normal")

    assert_log_contains "crawler_stopped"
    assert_log_contains "elapsed_seconds"
  end

  test "crawler_error increments system_errors" do
    @reporter.crawler_error(StandardError.new("something went wrong"))

    assert_equal 1, @reporter.metrics[:system_errors]
    assert_log_contains "crawler_error"
  end

  # === Summary ===

  test "summary returns metrics with elapsed time" do
    @reporter.crawl_started(@feed)
    @reporter.crawl_completed(@feed, { new_items: 1, updated_items: 0 })

    summary = @reporter.summary

    assert_operator summary[:elapsed_seconds], :>=, 0
    assert_equal 1, summary[:crawls_started]
    assert_equal 1, summary[:crawls_completed]
  end

  test "summary_line returns human-readable string" do
    @reporter.crawl_started(@feed)
    @reporter.crawl_completed(@feed, { new_items: 5, updated_items: 3 })
    @reporter.crawl_failed(@feed, "error", category: :transient)

    line = @reporter.summary_line

    assert_includes line, "Crawls:"
    assert_includes line, "Items:"
    assert_includes line, "Errors:"
  end

  # === Structured Logging ===

  test "structured mode outputs JSON" do
    reporter = Fastladder::CrawlerReporter.new(logger: @logger, structured: true)
    reporter.crawl_started(@feed)

    log_content = @log_output.string
    # Should contain valid JSON
    assert_includes log_content, '"event":"crawl_started"'
    assert_includes log_content, '"feed_id":'
  end

  # === Metrics Class ===

  test "Metrics reset clears all values" do
    metrics = Fastladder::Metrics.new
    metrics.increment(:crawls_started)
    metrics.add(:items_new, 10)

    metrics.reset

    assert_equal 0, metrics[:crawls_started]
    assert_equal 0, metrics[:items_new]
  end

  test "Metrics to_h includes all counters and sums" do
    metrics = Fastladder::Metrics.new
    hash = metrics.to_h

    assert hash.key?(:crawls_started)
    assert hash.key?(:items_new)
  end

  private

  def assert_log_contains(text)
    assert_includes @log_output.string, text, "Expected log to contain '#{text}'"
  end

  def mock_fetch_result(success: false, not_modified: false, redirect: false, error: false,
                        status_code: nil, attempts: 1, redirect_url: nil, error_message: nil,
                        retries_exhausted: false)
    result = Minitest::Mock.new
    result.expect(:success?, success)
    result.expect(:not_modified?, not_modified) unless success
    result.expect(:redirect?, redirect) unless success || not_modified
    result.expect(:status_code, status_code) if status_code
    result.expect(:attempts, attempts) if success || error
    result.expect(:redirect_url, redirect_url) if redirect
    result.expect(:error_message, error_message) if error
    result.expect(:retries_exhausted?, retries_exhausted) if error
    result
  end

  def mock_parse_result(success:, item_count: 0, error: nil)
    result = Minitest::Mock.new
    result.expect(:success?, success)
    if success
      # item_count is called twice: once for metrics, once for logging
      result.expect(:item_count, item_count)
      result.expect(:item_count, item_count)
    else
      result.expect(:error, error)
    end
    result
  end
end
