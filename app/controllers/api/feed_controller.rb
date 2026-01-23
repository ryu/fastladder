class Api::FeedController < ApplicationController
  include BulkSubscriptionUpdates

  before_action :login_required_api
  params_required :url, only: :discover
  params_required :feedlink, only: :subscribe
  params_required :subscribe_id, only: [:unsubscribe, :update, :move]
  params_required [:subscribe_id, :rate], only: :set_rate
  params_required [:subscribe_id, :ignore], only: :set_notify
  params_required [:subscribe_id, :public], only: :set_public
  skip_before_action :verify_authenticity_token

  def discover
    feeds = []
    url = Addressable::URI.parse(params[:url])
    FeedSearcher.search(url.normalize.to_s).each do |feedlink|
      feedlink = (url + feedlink).to_s
      if feed = Feed.find_by(feedlink: feedlink)
        result = {
          subscribers_count: feed.subscribers_count,
          feedlink: feed.feedlink,
          link: feed.link,
          title: feed.title,
        }
        if sub = @member.subscriptions.find_by(feed_id: feed.id)
          result[:subscribe_id] = sub.id
        end
        feeds << result
      else
        html = Fastladder.simple_fetch(feedlink)
        logger.debug html
        unless feed = Feedjira.parse(html)
          next
        end
        feeds << {
          subscribers_count: 0,
          feedlink: feedlink.html_escape,
          link: (feed.url || feedlink).html_escape,
          title: (feed.title || feed.url || "").utf8_roundtrip.html_escape,
        }
      end
    end
    render json: feeds.to_json
  end

  def subscribe
    feedlink = params[:feedlink]
    options = {
      folder_id: 0,
      rate: 0,
      public: @member.default_public,
    }
    if params[:folder_id]
      folder_id = params[:folder_id].to_i
      if @member.folders.exists?(folder_id)
        options[:folder_id] = folder_id
      else
        return render_json_status(false)
      end
    end
    if rate = params[:rate] and (0..5).include?(rate = rate.to_i)
      options[:rate] = rate
    end
    if pub = params[:public]
      options[:public] = pub.to_i != 0
    end

    unless sub = subscribe_feed(feedlink, options)
      return render_json_status(false)
    end
    render_json_status(true, subscribe_id: sub.id)
  end

  def unsubscribe
    sub = self.get_subscription
    sub.destroy
    render_json_status(true)
  end

  def subscribed
    feedlink = params[:feedlink]
    sub_id = (params[:subscribe_id] || 0).to_i
    sub = nil
    if sub_id > 0
      sub = @member.subscriptions.find_by(id: sub_id) || @member.subscriptions.find_by(feed_id: sub_id)
    else
      if feedlink.blank? or (feed = Feed.find_by(feedlink: feedlink)).nil?
        return render_json_status(false)
      end
      sub = @member.subscriptions.find_by(feed_id: feed.id)
    end
    unless sub
      return render_json_status(false)
    end
    result = {
      ApiKey: session[:session_id],
      subscribe_id: sub.id,
      folder_id: sub.folder_id || 0,
      rate: sub.rate,
      public: sub.public ? 1 : 0,
      ignore_notify: sub.ignore_notify ? 1 : 0,
      created_on: sub.created_on.to_time.to_i,
    }
    render json: result.to_json
  end

  def update
    sub = get_subscription
    sub.apply_settings(
      rate: params[:rate]&.to_i,
      is_public: parse_boolean(params[:public]),
      folder_id: validated_folder_id(params[:folder_id]),
      ignore_notify: parse_boolean(params[:ignore_notify])
    )
    render_json_status(true)
  end

  def move
    folder = @member.find_folder_by_name_or_id(params[:to])
    member_subscriptions(parse_subscription_ids).update_all(folder_id: folder&.id)
    render_json_status(true)
  end

  def set_rate
    sub = get_subscription
    rate = params[:rate].to_i
    sub.update!(rate: rate) if (0..5).cover?(rate)
    render_json_status(true)
  end

  def set_notify
    ignore = parse_boolean(params[:ignore])
    return render_json_status(false) if ignore.nil?

    member_subscriptions(parse_subscription_ids).update_all(ignore_notify: ignore)
    render_json_status(true)
  end

  def set_public
    is_public = parse_boolean(params[:public])
    return render_json_status(false) if is_public.nil?

    member_subscriptions(parse_subscription_ids).update_all(public: is_public)
    render_json_status(true)
  end

  def add_tags
  end

  def remove_tags
  end

  def fetch_favicon
    feedlink = params[:feedlink]
    if feedlink.blank? or (feed = Feed.find_by(feedlink: feedlink)).nil?
      return render_json_status(false)
    end
    feed.fetch_favicon!
    render_json_status(true)
  end

  protected

  def subscribe_feed(feedlink, options)
    @member.subscribe_feed(feedlink, options)
  end

  def get_subscription
    if params[:subscribe_id].blank? or (sub_id = params[:subscribe_id].to_i) <= 0
      return nil
    end
    @member.subscriptions.find_by(id: sub_id)
  end
end
