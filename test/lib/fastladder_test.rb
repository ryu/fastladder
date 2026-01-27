require "test_helper"

class FastladderTest < ActiveSupport::TestCase
  setup do
    # Reset to defaults before each test
    @original_proxy = Fastladder.http_proxy
    @original_timeout = Fastladder.http_open_timeout
    @original_read_timeout = Fastladder.http_read_timeout
  end

  teardown do
    # Restore original values
    Fastladder.instance_variable_set(:@http_proxy, @original_proxy)
    Fastladder.instance_variable_set(:@http_open_timeout, @original_timeout)
    Fastladder.instance_variable_set(:@http_read_timeout, @original_read_timeout)
  end

  test "configure yields self and sets defaults" do
    Fastladder.configure do |config|
      config.open_timeout = 120
      config.read_timeout = 180
    end

    assert_equal 120, Fastladder.http_open_timeout
    assert_equal 180, Fastladder.http_read_timeout
  end

  test "proxy= with URI object" do
    uri = URI.parse("http://proxy.example.com:8080")
    Fastladder.proxy = uri

    assert_equal uri, Fastladder.http_proxy
  end

  test "proxy= with Hash" do
    Fastladder.proxy = { host: "proxy.example.com", port: 8080 }

    assert_kind_of URI::HTTP, Fastladder.http_proxy
    assert_equal "proxy.example.com", Fastladder.http_proxy.host
    assert_equal 8080, Fastladder.http_proxy.port
  end

  test "proxy= with Hash and https scheme" do
    Fastladder.proxy = { scheme: "https", host: "proxy.example.com", port: 443 }

    assert_kind_of URI::HTTPS, Fastladder.http_proxy
  end

  test "proxy= with Hash and invalid scheme does nothing" do
    original = Fastladder.http_proxy
    Fastladder.proxy = { scheme: "ftp", host: "proxy.example.com" }

    assert_equal original, Fastladder.http_proxy
  end

  test "proxy= with string URL" do
    Fastladder.proxy = "http://proxy.example.com:3128"

    assert_kind_of URI::HTTP, Fastladder.http_proxy
    assert_equal "proxy.example.com", Fastladder.http_proxy.host
    assert_equal 3128, Fastladder.http_proxy.port
  end

  test "proxy= with invalid string URL sets nil" do
    Fastladder.proxy = "not a valid url %%%"

    assert_nil Fastladder.http_proxy
  end

  test "proxy= with blank value does nothing" do
    original = Fastladder.http_proxy
    Fastladder.proxy = ""

    assert_equal original, Fastladder.http_proxy
  end

  test "proxy= with non-HTTP URI sets nil" do
    Fastladder.proxy = "ftp://ftp.example.com"

    assert_nil Fastladder.http_proxy
  end

  test "changes http_proxy_except_hosts" do
    Fastladder.proxy_except_hosts = [/foo/, :bar, "buz"]

    assert_equal [/foo/], Fastladder.http_proxy_except_hosts
  end

  test "changes http_open_timeout" do
    Fastladder.open_timeout = 100

    assert_equal 100, Fastladder.http_open_timeout
  end

  test "changes http_read_timeout" do
    Fastladder.read_timeout = 200

    assert_equal 200, Fastladder.http_read_timeout
  end

  test "changes crawler_user_agent" do
    Fastladder.crawler_user_agent = "YetAnother FeedFetcher/0.0.3 (http://example.com/)"

    assert_equal "YetAnother FeedFetcher/0.0.3 (http://example.com/)", Fastladder.crawler_user_agent
  end

  test "simple_fetch can handle http => https redirect" do
    stub_request(:get, "http://example.com")
      .to_return(status: 301, headers: { "Location" => "https://example.com" })

    stub_request(:get, "https://example.com")
      .to_return(status: 200, body: "Success")

    assert_equal "Success", Fastladder.simple_fetch("http://example.com")
  end
end
