# frozen_string_literal: true

class Api::Feed::DiscoveriesController < ApplicationController
  before_action :login_required_api
  skip_before_action :verify_authenticity_token

  # POST /api/feed/discoveries (alias: /api/feed/discover)
  def create
    url = Addressable::URI.parse(params[:url])
    feeds = []

    FeedSearcher.search(url.normalize.to_s).each do |feedlink|
      feedlink = (url + feedlink).to_s
      feeds << build_feed_result(feedlink)
    end

    render json: feeds.compact
  end

  private

  def build_feed_result(feedlink)
    if (feed = Feed.find_by(feedlink: feedlink))
      result = {
        subscribers_count: feed.subscribers_count,
        feedlink: feed.feedlink,
        link: feed.link,
        title: feed.title
      }
      if (sub = @member.subscriptions.find_by(feed_id: feed.id))
        result[:subscribe_id] = sub.id
      end
      result
    else
      html = Fastladder.simple_fetch(feedlink)
      Rails.logger.debug html
      feed = Feedjira.parse(html)
      return nil unless feed

      {
        subscribers_count: 0,
        feedlink: feedlink.html_escape,
        link: (feed.url || feedlink).html_escape,
        title: (feed.title || feed.url || "").utf8_roundtrip.html_escape
      }
    end
  end
end
