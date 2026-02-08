# frozen_string_literal: true

module RecordCreationHelper
  def create_member(attrs = {})
    defaults = {
      username: "user_#{SecureRandom.hex(4)}",
      password: "mala",
      password_confirmation: "mala"
    }
    Member.create!(defaults.merge(attrs))
  end

  def create_feed(attrs = {})
    defaults = {
      feedlink: "http://test.example.com/feed/#{SecureRandom.hex(4)}",
      link: "http://test.example.com/",
      title: "Test Feed",
      description: ""
    }
    Feed.create!(defaults.merge(attrs))
  end

  def create_item(attrs = {})
    defaults = {
      link: "http://test.example.com/item/#{SecureRandom.hex(4)}",
      title: "Test Item",
      body: "body",
      guid: SecureRandom.hex(8),
      stored_on: Time.current,
      modified_on: Time.current,
      created_on: Time.current
    }
    Item.create!(defaults.merge(attrs))
  end

  def create_subscription(attrs = {})
    attrs[:feed] ||= create_feed
    Subscription.create!(attrs)
  end

  def create_pin(attrs = {})
    defaults = {
      link: "http://test.example.com/pin/#{SecureRandom.hex(4)}",
      title: "Test Pin"
    }
    Pin.create!(defaults.merge(attrs))
  end

  def create_crawl_status(attrs = {})
    CrawlStatus.create!(attrs)
  end

  def create_folder(attrs = {})
    defaults = { name: "Folder_#{SecureRandom.hex(4)}" }
    Folder.create!(defaults.merge(attrs))
  end
end
