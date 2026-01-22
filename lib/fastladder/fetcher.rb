# frozen_string_literal: true

require "net/http"
require "uri"
require "openssl"

module Fastladder
  # Fetcher handles HTTP fetching with retry, backoff, and rate limiting.
  #
  # This class separates HTTP concerns from crawler business logic:
  # - Retry with exponential backoff for transient failures
  # - Rate limiting to respect server resources
  # - Error classification (retryable vs non-retryable)
  # - Clean interface for testing
  #
  # @example Basic usage
  #   fetcher = Fastladder::Fetcher.new(logger: Rails.logger)
  #   result = fetcher.fetch("https://example.com/feed.xml")
  #   if result.success?
  #     process(result.body)
  #   elsif result.not_modified?
  #     # skip processing
  #   else
  #     handle_error(result.error)
  #   end
  #
  class Fetcher
    # Default configuration
    DEFAULT_MAX_RETRIES = 3
    DEFAULT_BASE_DELAY = 1.0       # seconds
    DEFAULT_MAX_DELAY = 60.0       # seconds
    DEFAULT_RATE_LIMIT_DELAY = 0.5 # seconds between requests
    DEFAULT_OPEN_TIMEOUT = 30      # seconds
    DEFAULT_READ_TIMEOUT = 60      # seconds

    # HTTP status codes that warrant a retry
    RETRYABLE_HTTP_CODES = [408, 429, 500, 502, 503, 504].freeze

    # Exceptions that warrant a retry
    RETRYABLE_EXCEPTIONS = [
      Timeout::Error,
      Errno::ECONNRESET,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      Errno::ETIMEDOUT,
      Net::OpenTimeout,
      Net::ReadTimeout,
      OpenSSL::SSL::SSLError,
      SocketError
    ].freeze

    attr_accessor :max_retries, :base_delay, :max_delay, :rate_limit_delay, :open_timeout, :read_timeout
    attr_reader :logger

    def initialize(
      logger: nil,
      max_retries: DEFAULT_MAX_RETRIES,
      base_delay: DEFAULT_BASE_DELAY,
      max_delay: DEFAULT_MAX_DELAY,
      rate_limit_delay: DEFAULT_RATE_LIMIT_DELAY,
      open_timeout: DEFAULT_OPEN_TIMEOUT,
      read_timeout: DEFAULT_READ_TIMEOUT
    )
      @logger = logger
      @max_retries = max_retries
      @base_delay = base_delay
      @max_delay = max_delay
      @rate_limit_delay = rate_limit_delay
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @last_request_time = nil
    end

    # Fetch a URL with retry and rate limiting.
    #
    # @param url [String, URI] The URL to fetch
    # @param modified_since [Time, String, nil] If-Modified-Since header value
    # @param user_agent [String, nil] Custom User-Agent header
    # @param user [String, nil] Basic auth username
    # @param password [String, nil] Basic auth password
    # @return [FetchResult] The result of the fetch operation
    def fetch(url, modified_since: nil, user_agent: nil, user: nil, password: nil)
      uri = normalize_uri(url)
      return FetchResult.invalid_url(url) unless uri

      apply_rate_limit

      attempt = 0
      last_error = nil
      last_response = nil

      while attempt <= max_retries
        attempt += 1
        log_debug("Fetch attempt #{attempt}/#{max_retries + 1}: #{uri}")

        begin
          response = perform_request(uri, modified_since: modified_since, user_agent: user_agent, user: user, password: password)
          result = FetchResult.from_response(response, uri, attempts: attempt)

          # Return immediately for success, not-modified, redirect, or non-retryable errors
          return result unless result.retryable_error?

          # Retryable HTTP error - save response and continue to retry logic
          last_response = response
          last_error = nil
          log_warn("Retryable HTTP error (#{response.code}): #{uri}")
        rescue *RETRYABLE_EXCEPTIONS => e
          last_error = e
          last_response = nil
          log_warn("Retryable exception (#{e.class}): #{uri} - #{e.message}")
        rescue StandardError => e
          # Non-retryable exception
          log_error("Non-retryable exception (#{e.class}): #{uri} - #{e.message}")
          return FetchResult.error(e, uri, attempts: attempt)
        end

        # Apply backoff before retry (except for the last attempt)
        next unless attempt <= max_retries

        delay = calculate_backoff(attempt)
        log_debug("Backing off for #{delay.round(2)}s before retry")
        sleep(delay)
      end

      # All retries exhausted
      log_error("All #{max_retries + 1} attempts failed: #{uri}")
      if last_response
        # Return the last HTTP response with retries_exhausted flag
        FetchResult.new(response: last_response, uri: uri, attempts: attempt, retries_exhausted: true)
      else
        # Return error from exception
        FetchResult.error(last_error, uri, attempts: attempt, retries_exhausted: true)
      end
    end

    private

    def normalize_uri(url)
      uri = url.is_a?(URI) ? url : URI.parse(url.to_s)
      return nil unless %w[http https].include?(uri.scheme)

      uri
    rescue URI::InvalidURIError
      nil
    end

    def apply_rate_limit
      return unless rate_limit_delay.positive? && @last_request_time

      elapsed = Time.zone.now - @last_request_time
      remaining = rate_limit_delay - elapsed
      if remaining.positive?
        log_debug("Rate limiting: sleeping #{remaining.round(2)}s")
        sleep(remaining)
      end
    ensure
      @last_request_time = Time.zone.now
    end

    def perform_request(uri, modified_since:, user_agent:, user:, password:)
      http = build_http_client(uri)
      request = build_request(uri, modified_since: modified_since, user_agent: user_agent, user: user, password: password)

      http.start do |conn|
        conn.request(request)
      end
    end

    def build_http_client(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = open_timeout
      http.read_timeout = read_timeout

      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      http
    end

    def build_request(uri, modified_since:, user_agent:, user:, password:)
      request = Net::HTTP::Get.new(uri.request_uri)
      request["Accept"] = Fastladder::HTTP_ACCEPT
      request["User-Agent"] = user_agent || default_user_agent
      request["If-Modified-Since"] = format_modified_since(modified_since) if modified_since

      # Basic auth (from options or URI)
      auth_user = user || uri.user
      auth_pass = password || uri.password
      request.basic_auth(auth_user, auth_pass) if auth_user

      request
    end

    def default_user_agent
      Fastladder.crawler_user_agent || "Fastladder FeedFetcher/#{Fastladder::Version} (http://fastladder.org/)"
    end

    def format_modified_since(value)
      case value
      when Time, DateTime
        value.httpdate
      else
        value.to_s
      end
    end

    def calculate_backoff(attempt)
      # Exponential backoff with jitter: base * 2^(attempt-1) + random jitter
      delay = base_delay * (2**(attempt - 1))
      delay = [delay, max_delay].min
      # Add jitter (0-25% of delay)
      delay + (rand * delay * 0.25)
    end

    def log_debug(message)
      logger&.debug("[Fetcher] #{message}")
    end

    def log_warn(message)
      logger&.warn("[Fetcher] #{message}")
    end

    def log_error(message)
      logger&.error("[Fetcher] #{message}")
    end
  end

  # FetchResult encapsulates the result of a fetch operation.
  #
  # This provides a clean interface for inspecting fetch results
  # without exposing raw Net::HTTP response details.
  #
  class FetchResult
    attr_reader :response, :uri, :error, :attempts

    def initialize(response: nil, uri: nil, error: nil, attempts: 1, retries_exhausted: false, invalid_url: false)
      @response = response
      @uri = uri
      @error = error
      @attempts = attempts
      @retries_exhausted = retries_exhausted
      @invalid_url = invalid_url
    end

    # Factory methods

    def self.from_response(response, uri, attempts: 1)
      new(response: response, uri: uri, attempts: attempts)
    end

    def self.error(error, uri, attempts: 1, retries_exhausted: false)
      new(error: error, uri: uri, attempts: attempts, retries_exhausted: retries_exhausted)
    end

    def self.invalid_url(url)
      new(error: ArgumentError.new("Invalid URL: #{url}"), invalid_url: true)
    end

    # Status checks

    def success?
      response.is_a?(Net::HTTPSuccess)
    end

    def not_modified?
      response.is_a?(Net::HTTPNotModified)
    end

    def redirect?
      response.is_a?(Net::HTTPRedirection)
    end

    def client_error?
      response.is_a?(Net::HTTPClientError)
    end

    def server_error?
      response.is_a?(Net::HTTPServerError)
    end

    def error?
      !response || client_error? || server_error? || @error
    end

    def retryable_error?
      return false unless response

      Fetcher::RETRYABLE_HTTP_CODES.include?(status_code)
    end

    def retries_exhausted?
      @retries_exhausted
    end

    def invalid_url?
      @invalid_url
    end

    # Response data

    def status_code
      response&.code&.to_i
    end

    def status_message
      response&.message
    end

    def body
      response&.body
    end

    def redirect_url
      return nil unless redirect?

      location = response["location"]
      return nil unless location

      URI.join(uri, location).to_s
    rescue URI::InvalidURIError
      nil
    end

    def headers
      return {} unless response

      response.to_hash
    end

    # Error information

    def error_message
      if @error
        "#{@error.class}: #{@error.message}"
      elsif error?
        "HTTP #{status_code}: #{status_message}"
      end
    end

    def to_s
      if success?
        "FetchResult[OK #{status_code}] #{uri}"
      elsif not_modified?
        "FetchResult[NotModified] #{uri}"
      elsif redirect?
        "FetchResult[Redirect #{status_code}] #{uri} -> #{redirect_url}"
      elsif error?
        "FetchResult[Error] #{uri}: #{error_message}"
      else
        "FetchResult[#{status_code}] #{uri}"
      end
    end
  end
end
