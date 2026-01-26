# == Schema Information
#
# Table name: feeds
#
#  id                :integer          not null, primary key
#  feedlink          :string(255)      not null
#  link              :string(255)      not null
#  title             :text             not null
#  description       :text             not null
#  subscribers_count :integer          default(0), not null
#  image             :string(255)
#  icon              :string(255)
#  modified_on       :datetime
#  created_on        :datetime         not null
#  updated_on        :datetime         not null
#

class Feed < ApplicationRecord
  include Feed::Crawlable
  include Feed::FaviconFetchable

  has_one :crawl_status
  has_one :favicon
  has_many :items
  has_many :subscriptions

  before_save :except_fragment_identifier, :default_values

  attr_accessor :subscribe_id

  scope :has_subscriptions, -> { where("subscribers_count > 0") }
  scope :crawlable, lambda {
    includes(:crawl_status)
      .joins(:crawl_status)
      .has_subscriptions
      .merge(CrawlStatus.status_ok)
      .merge(CrawlStatus.expired(Settings.crawl_interval.minutes))
  }

  def description
    CGI.escapeHTML self[:description].to_s
  end

  def description=(str)
    self[:description] = str.to_s
  end

  def self.initialize_from_uri(uri)
    feed_dom = Feedjira.parse(Fastladder.simple_fetch(uri))
    return nil unless feed_dom

    new(
      feedlink: uri.to_s,
      link: feed_dom.url || uri.to_s,
      title: feed_dom.title || feed_dom.url || "",
      description: feed_dom.description || ""
    )
  end

  def self.create_from_uri(uri)
    feed = initialize_from_uri(uri)
    return nil unless feed

    feed.save
    feed.create_crawl_status
    feed
  end

  def to_json(_options = {})
    result = {}
    %i[title description].each do |s|
      result[s] = (send(s) || "").purify_html
    end
    %i[feedlink link image].each do |s|
      result[s] = (send(s) || "").purify_uri
    end

    result[:expires] = 0
    result[:subscribers_count] = subscribers_count
    result[:error_count] = crawl_status.error_count
    result.to_json
  end

  def subscribed(member)
    member.subscribed(self)
  end

  def update_subscribers_count
    logger.warn "subscribers: #{subscribers_count}"
    update(subscribers_count: subscriptions.size)
  end

  def avg_rate
    subscriptions.where("rate > ?", 0).average(:rate).to_i
  end

  def except_fragment_identifier
    self.feedlink = begin
      parsed_feedlink = Addressable::URI.parse(feedlink)
      parsed_feedlink.fragment = nil
      parsed_feedlink.to_s
    rescue StandardError
      feedlink
    end
  end

  def default_values
    self.title ||= ""
    self.description ||= ""
  end
end
