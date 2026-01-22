# frozen_string_literal: true

require "test_helper"

class Fastladder::FetcherTest < ActiveSupport::TestCase
  def setup
    @fetcher = Fastladder::Fetcher.new(
      logger: Rails.logger,
      max_retries: 2,
      base_delay: 0.01,  # Fast tests
      rate_limit_delay: 0 # Disable for most tests
    )
    @test_url = "https://example.com/feed.xml"
  end

  # === Success Cases ===

  test "fetch returns success for HTTP 200" do
    stub_request(:get, @test_url)
      .to_return(status: 200, body: "<feed>content</feed>")

    result = @fetcher.fetch(@test_url)

    assert result.success?
    assert_equal 200, result.status_code
    assert_equal "<feed>content</feed>", result.body
    assert_equal 1, result.attempts
  end

  test "fetch returns not_modified for HTTP 304" do
    stub_request(:get, @test_url)
      .to_return(status: 304)

    result = @fetcher.fetch(@test_url)

    assert result.not_modified?
    assert_equal 304, result.status_code
    refute result.success?
    refute result.error?
  end

  test "fetch sends If-Modified-Since header when provided" do
    modified_time = Time.utc(2025, 1, 15, 10, 30, 0)
    stub_request(:get, @test_url)
      .with(headers: { "If-Modified-Since" => modified_time.httpdate })
      .to_return(status: 304)

    result = @fetcher.fetch(@test_url, modified_since: modified_time)

    assert result.not_modified?
  end

  test "fetch sends custom User-Agent when provided" do
    stub_request(:get, @test_url)
      .with(headers: { "User-Agent" => "CustomAgent/1.0" })
      .to_return(status: 200, body: "ok")

    result = @fetcher.fetch(@test_url, user_agent: "CustomAgent/1.0")

    assert result.success?
  end

  # === Redirect Cases ===

  test "fetch returns redirect for HTTP 301" do
    stub_request(:get, @test_url)
      .to_return(status: 301, headers: { "Location" => "https://example.com/new-feed.xml" })

    result = @fetcher.fetch(@test_url)

    assert result.redirect?
    assert_equal 301, result.status_code
    assert_equal "https://example.com/new-feed.xml", result.redirect_url
  end

  test "fetch handles relative redirect URLs" do
    stub_request(:get, @test_url)
      .to_return(status: 302, headers: { "Location" => "/another-feed.xml" })

    result = @fetcher.fetch(@test_url)

    assert result.redirect?
    assert_equal "https://example.com/another-feed.xml", result.redirect_url
  end

  # === Error Cases ===

  test "fetch returns error for HTTP 404" do
    stub_request(:get, @test_url)
      .to_return(status: 404, body: "Not Found")

    result = @fetcher.fetch(@test_url)

    assert result.error?
    assert result.client_error?
    assert_equal 404, result.status_code
    refute result.retryable_error?
  end

  test "fetch returns error for HTTP 500" do
    stub_request(:get, @test_url)
      .to_return(status: 500, body: "Internal Server Error")

    result = @fetcher.fetch(@test_url)

    assert result.error?
    assert result.server_error?
    assert_equal 500, result.status_code
  end

  test "fetch returns invalid_url error for invalid URLs" do
    result = @fetcher.fetch("not-a-valid-url")

    assert result.error?
    assert result.invalid_url?
    assert_includes result.error_message, "Invalid URL"
  end

  test "fetch returns invalid_url error for non-HTTP schemes" do
    result = @fetcher.fetch("ftp://example.com/file")

    assert result.error?
    assert result.invalid_url?
  end

  # === Retry Behavior ===

  test "fetch retries on timeout and succeeds" do
    stub_request(:get, @test_url)
      .to_timeout
      .then.to_return(status: 200, body: "success after retry")

    result = @fetcher.fetch(@test_url)

    assert result.success?
    assert_equal 2, result.attempts
    assert_equal "success after retry", result.body
  end

  test "fetch retries on HTTP 503 and succeeds" do
    stub_request(:get, @test_url)
      .to_return(status: 503)
      .then.to_return(status: 200, body: "success after 503")

    result = @fetcher.fetch(@test_url)

    assert result.success?
    assert_equal 2, result.attempts
  end

  test "fetch retries on HTTP 429 (rate limited)" do
    stub_request(:get, @test_url)
      .to_return(status: 429)
      .then.to_return(status: 200, body: "success after rate limit")

    result = @fetcher.fetch(@test_url)

    assert result.success?
    assert_equal 2, result.attempts
  end

  test "fetch exhausts retries and returns error" do
    stub_request(:get, @test_url)
      .to_timeout

    result = @fetcher.fetch(@test_url)

    assert result.error?
    assert result.retries_exhausted?
    assert_equal 3, result.attempts # 1 initial + 2 retries
  end

  test "fetch does not retry on HTTP 404" do
    stub_request(:get, @test_url)
      .to_return(status: 404)

    result = @fetcher.fetch(@test_url)

    assert result.error?
    assert_equal 1, result.attempts
    refute result.retries_exhausted?
  end

  test "fetch retries on connection refused" do
    stub_request(:get, @test_url)
      .to_raise(Errno::ECONNREFUSED)
      .then.to_return(status: 200, body: "recovered")

    result = @fetcher.fetch(@test_url)

    assert result.success?
    assert_equal 2, result.attempts
  end

  test "fetch does not retry on non-retryable exception" do
    stub_request(:get, @test_url)
      .to_raise(ArgumentError.new("bad argument"))

    result = @fetcher.fetch(@test_url)

    assert result.error?
    assert_equal 1, result.attempts
    assert_includes result.error_message, "ArgumentError"
  end

  # === Rate Limiting ===

  test "fetch applies rate limiting between requests" do
    fetcher = Fastladder::Fetcher.new(
      logger: Rails.logger,
      rate_limit_delay: 0.05
    )

    stub_request(:get, @test_url).to_return(status: 200, body: "ok")
    stub_request(:get, "https://example.com/feed2.xml").to_return(status: 200, body: "ok2")

    start_time = Time.now
    fetcher.fetch(@test_url)
    fetcher.fetch("https://example.com/feed2.xml")
    elapsed = Time.now - start_time

    assert elapsed >= 0.05, "Rate limiting should add delay between requests"
  end

  # === FetchResult ===

  test "FetchResult to_s for success" do
    stub_request(:get, @test_url).to_return(status: 200)
    result = @fetcher.fetch(@test_url)

    assert_includes result.to_s, "OK 200"
    assert_includes result.to_s, @test_url
  end

  test "FetchResult to_s for redirect" do
    stub_request(:get, @test_url)
      .to_return(status: 301, headers: { "Location" => "https://new.example.com/" })
    result = @fetcher.fetch(@test_url)

    assert_includes result.to_s, "Redirect 301"
    assert_includes result.to_s, "new.example.com"
  end

  test "FetchResult to_s for error" do
    stub_request(:get, @test_url).to_return(status: 500)
    result = @fetcher.fetch(@test_url)

    assert_includes result.to_s, "Error"
    assert_includes result.to_s, "500"
  end

  test "FetchResult headers returns response headers" do
    stub_request(:get, @test_url)
      .to_return(status: 200, headers: { "Content-Type" => "application/xml" })

    result = @fetcher.fetch(@test_url)

    assert_includes result.headers["content-type"], "application/xml"
  end

  # === URI and Authentication ===

  test "fetch accepts URI object" do
    uri = URI.parse(@test_url)
    stub_request(:get, @test_url).to_return(status: 200)

    result = @fetcher.fetch(uri)

    assert result.success?
  end

  test "fetch handles basic auth in options" do
    stub_request(:get, @test_url)
      .with(basic_auth: ["user", "pass"])
      .to_return(status: 200)

    result = @fetcher.fetch(@test_url, user: "user", password: "pass")

    assert result.success?
  end

  test "fetch handles basic auth in URL" do
    authed_url = "https://user:pass@example.com/feed.xml"
    # The actual HTTP request goes to the URL without credentials
    stub_request(:get, "https://example.com/feed.xml")
      .with(basic_auth: ["user", "pass"])
      .to_return(status: 200)

    result = @fetcher.fetch(authed_url)

    assert result.success?
  end
end
