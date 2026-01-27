require "test_helper"

class ImportControllerTest < ActionController::TestCase
  def setup
    @member = create_member(password: "mala", password_confirmation: "mala")
  end

  test "GET index requires login" do
    get :index

    assert_redirected_to login_path
  end

  test "GET index renders import page" do
    get :index, session: { member_id: @member.id }

    assert_response :success
  end

  test "POST fetch requires login" do
    post :fetch, params: { url: "http://example.com" }

    assert_redirected_to login_path
  end

  test "POST fetch calls simple_fetch" do
    Fastladder.stub :simple_fetch, "<opml/>" do
      post :fetch, params: { url: "http://example.com" }, session: { member_id: @member.id }

      assert_response :success
    end
  end

  test "POST fetch assigns folder" do
    opml_content = Rails.root.join("test/stubs/opml").read
    Fastladder.stub :simple_fetch, opml_content do
      post :fetch, params: { url: "http://example.com" }, session: { member_id: @member.id }

      assert_includes assigns[:folders].keys, "Subscriptions"
    end
  end

  test "POST fetch assigns item" do
    opml_content = Rails.root.join("test/stubs/opml").read
    Fastladder.stub :simple_fetch, opml_content do
      post :fetch, params: { url: "http://example.com" }, session: { member_id: @member.id }
      item = assigns[:folders]["Subscriptions"][0]

      assert_equal "Recent Commits to fastladder:master", item[:title]
      assert_equal "https://github.com/fastladder/fastladder/commits/master", item[:link]
      assert_equal "https://github.com/fastladder/fastladder/commits/master.atom", item[:feedlink]
      assert_not item[:subscribed]
    end
  end

  test "POST fetch with file upload" do
    opml_content = Rails.root.join("test/stubs/opml").read
    opml_file = Rack::Test::UploadedFile.new(
      StringIO.new(opml_content),
      "text/xml",
      original_filename: "subscriptions.opml"
    )

    post :fetch, params: { opml: opml_file }, session: { member_id: @member.id }

    assert_response :success
    assert_includes assigns[:folders].keys, "Subscriptions"
  end

  test "POST fetch with invalid opml returns nil" do
    Fastladder.stub :simple_fetch, "not valid opml" do
      post :fetch, params: { url: "http://example.com" }, session: { member_id: @member.id }

      assert_response :success
    end
  end

  test "POST finish requires login" do
    post :finish

    assert_redirected_to login_path
  end

  test "POST finish subscribes to selected feeds" do
    stub_request(:get, "https://example.com/feed.xml")
      .to_return(status: 200, body: sample_rss_feed, headers: { "Content-Type" => "application/rss+xml" })

    post :finish, params: {
      titles: { "0" => "Example Feed" },
      feedlinks: { "0" => "Tech:https://example.com/feed.xml" },
      check_for_subscribes: { "0" => "1" }
    }, session: { member_id: @member.id }

    assert_redirected_to reader_path
    assert @member.folders.exists?(name: "Tech")
    assert @member.subscriptions.joins(:feed).exists?(feeds: { feedlink: "https://example.com/feed.xml" })
  end

  test "POST finish skips unchecked feeds" do
    post :finish, params: {
      titles: { "0" => "Example Feed" },
      feedlinks: { "0" => "Tech:https://example.com/feed.xml" },
      check_for_subscribes: { "0" => "0" }
    }, session: { member_id: @member.id }

    assert_redirected_to reader_path
    assert_not @member.subscriptions.joins(:feed).exists?(feeds: { feedlink: "https://example.com/feed.xml" })
  end

  private

  def sample_rss_feed
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Example Feed</title>
          <link>https://example.com</link>
          <description>An example feed</description>
          <item>
            <title>Test Item</title>
            <link>https://example.com/item1</link>
            <description>Test content</description>
          </item>
        </channel>
      </rss>
    XML
  end
end
