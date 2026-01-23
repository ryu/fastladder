require "test_helper"

class FeedTest < ActiveSupport::TestCase
  test "initialize_from_uri sets title correctly" do
    stub_content = File.read(Rails.root.join("test/stubs/github.atom"))
    Fastladder.stub :simple_fetch, stub_content do
      feed = Feed.initialize_from_uri("https://github.com/fastladder/fastladder/commits/master.atom")
      assert_equal "Recent Commits to fastladder:master", feed.title
    end
  end

  test "initialize_from_uri sets feedlink correctly" do
    stub_content = File.read(Rails.root.join("test/stubs/github.atom"))
    Fastladder.stub :simple_fetch, stub_content do
      feed = Feed.initialize_from_uri("https://github.com/fastladder/fastladder/commits/master.atom")
      assert_equal "https://github.com/fastladder/fastladder/commits/master.atom", feed.feedlink
    end
  end

  test "initialize_from_uri sets link correctly" do
    stub_content = File.read(Rails.root.join("test/stubs/github.atom"))
    Fastladder.stub :simple_fetch, stub_content do
      feed = Feed.initialize_from_uri("https://github.com/fastladder/fastladder/commits/master.atom")
      assert_equal "https://github.com/fastladder/fastladder/commits/master", feed.link
    end
  end

  test "initialize_from_uri sets description correctly" do
    stub_content = File.read(Rails.root.join("test/stubs/github.atom"))
    Fastladder.stub :simple_fetch, stub_content do
      feed = Feed.initialize_from_uri("https://github.com/fastladder/fastladder/commits/master.atom")
      assert_equal "", feed.description
    end
  end

  test "create_from_uri creates feed" do
    stub_content = File.read(Rails.root.join("test/stubs/github.atom"))
    Fastladder.stub :simple_fetch, stub_content do
      assert_difference "Feed.count", 1 do
        Feed.create_from_uri("https://github.com/fastladder/fastladder/commits/master.atom")
      end
    end
  end

  test "create_from_uri creates crawl_status" do
    stub_content = File.read(Rails.root.join("test/stubs/github.atom"))
    Fastladder.stub :simple_fetch, stub_content do
      assert_difference "CrawlStatus.count", 1 do
        Feed.create_from_uri("https://github.com/fastladder/fastladder/commits/master.atom")
      end
    end
  end

  test "removes fragment from feedlink" do
    feed = create_feed(feedlink: "http://example.com/rss#_=_")
    assert_equal "http://example.com/rss", feed.feedlink
  end

  test "stores favicon.ico as PNG" do
    feed = create_feed
    favicon = File.read(Rails.root.join("test/fixtures/favicon.ico"))
    stub_request(:get, feed.link).to_return(body: "<html></html>")
    stub_request(:get, feed.feedlink).to_return(body: "")
    stub_request(:any, /favicon/).to_return(headers: { "Content-Type" => "image/vnd.microsoft.icon" }, body: favicon)
    feed.fetch_favicon!
    assert feed.favicon.image.start_with?("\x89PNG\r\n".b)
  end

  test "handles gif favicon returning vnd.microsoft.icon" do
    feed = create_feed
    favicon = File.read(Rails.root.join("test/fixtures/favicon.ico"))
    stub_request(:any, /.*/).to_return(body: favicon, headers: { "Content-Type" => "image/vnd.microsoft.icon" })
    feed.stub :favicon_candidates, [Addressable::URI.parse("http://example.com/favicon?file=favicon.gif")] do
      feed.fetch_favicon!
      assert feed.favicon.image.start_with?("\x89PNG\r\n".b)
    end
  end

  test "logs errors when favicon.ico is not valid data" do
    feed = create_feed
    stub_request(:any, /.*/).to_return(body: "invalid image data")

    error_logged = false
    MiniMagick::Image.stub :open, ->(*args) { raise MiniMagick::Error } do
      Rails.logger.stub :error, ->(msg) { error_logged = true } do
        feed.fetch_favicon!
        assert error_logged
      end
    end
  end

  test "detects favicon url from feed.link" do
    favicon_url = Addressable::URI.parse("http://icon.example.com/favicon.gif").normalize
    feed = create_feed(link: "http://favicon-test.example.com/")
    stub_request(:get, feed.link).to_return(
      body: <<-HTML
        <html>
          <head>
            <link rel="shortcut icon" href="#{favicon_url.to_s}">
          </head>
          <body></body>
        </html>
      HTML
    )
    stub_request(:get, feed.feedlink).to_return(body: "")
    assert_includes feed.send(:favicon_candidates), favicon_url
  end

  test "crawlable includes ok feed with crawl_status" do
    ok_feed = create_feed_with_crawl_status({ subscribers_count: 1 }, { status: Fastladder::Crawler::CRAWL_OK })
    ng_feed = create_feed_with_crawl_status({ subscribers_count: 1 }, { status: Fastladder::Crawler::CRAWL_NOW })
    assert_includes Feed.crawlable, ok_feed
    refute_includes Feed.crawlable, ng_feed
  end

  test "crawlable includes ok feed with subscribers_count" do
    ok_feed = create_feed_with_crawl_status({ subscribers_count: 1 }, { status: Fastladder::Crawler::CRAWL_OK })
    ng_feed = create_feed_with_crawl_status({ subscribers_count: 0 }, { status: Fastladder::Crawler::CRAWL_OK })
    assert_includes Feed.crawlable, ok_feed
    refute_includes Feed.crawlable, ng_feed
  end

  test "crawlable includes ok feeds based on crawled_on" do
    ok_feed_1 = create_feed_with_crawl_status({ subscribers_count: 1 }, { crawled_on: nil })
    ok_feed_2 = create_feed_with_crawl_status({ subscribers_count: 1 }, { crawled_on: 31.minutes.ago })
    ng_feed = create_feed_with_crawl_status({ subscribers_count: 1 }, { crawled_on: 29.minutes.ago })
    assert_includes Feed.crawlable, ok_feed_1
    assert_includes Feed.crawlable, ok_feed_2
    refute_includes Feed.crawlable, ng_feed
  end

  test "calculates average rate" do
    feed = create_feed
    create_subscription(feed: feed, member: members(:member_one), rate: 5)
    create_subscription(feed: feed, member: members(:member_two), rate: 5)
    create_subscription(feed: feed, member: members(:member_three), rate: 3)
    assert_equal 4, feed.avg_rate
  end

  test "feed has default description" do
    feed = create_feed(description: nil)
    refute_nil feed.description
  end

  test "feed has default title" do
    feed = create_feed(title: nil)
    refute_nil feed.title
  end
end
