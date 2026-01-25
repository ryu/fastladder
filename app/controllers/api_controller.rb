class ApiController < ApplicationController
  before_action :login_required_api
  params_required :subscribe_id, only: :touch_all
  params_required %i[timestamp subscribe_id], only: :touch
  params_required :since, only: %i[item_count unread_count]
  before_action :find_sub, only: %i[all unread]
  skip_before_action :verify_authenticity_token

  def all
    if params[:limit].blank?
      limit = Settings.max_unread_count
    else
      limit = params[:limit].to_i
      limit = Settings.max_unread_count if limit <= 0 or Settings.max_unread_count < limit
    end
    offset = params[:offset].blank? ? 0 : params[:offset].to_i
    items = @sub.feed.items.recent(limit, offset)
    result = {
      subscribe_id: @id,
      channel: @sub.feed,
      items: items
    }
    result[:ignore_notify] = 1 if @sub.ignore_notify
    render json: result
  end

  def unread
    items = @sub.feed.items.stored_since(@sub.viewed_on).recent(Settings.max_unread_count)
    result = {
      subscribe_id: @id,
      channel: @sub.feed,
      items: items
    }
    result[:last_stored_on] = items.max_by(&:stored_on).stored_on if items.length > 0
    result[:ignore_notify] = 1 if @sub.ignore_notify
    render json: result
  end

  def touch_all
    updated_ids = []
    params[:subscribe_id].to_s.split(/\s*,\s*/).each do |id|
      if sub = @member.subscriptions.find_by(id: id)
        sub.update(has_unread: false, viewed_on: DateTime.now)
        updated_ids << id.to_i
      end
    end

    if turbo_stream_request?
      streams = updated_ids.map do |id|
        turbo_stream.replace("subscription-unread-#{id}",
                             html: '<span class="unread-count" data-count="0">0</span>')
      end
      render turbo_stream: streams
    else
      render_json_status(true)
    end
  end

  def touch
    timestamps = params[:timestamp].split(/\s*, \s*/).map { |t| t.to_i }
    params[:subscribe_id].split(/\s*,\s*/).each_with_index do |id, i|
      if sub = Subscription.find(id) and sub.member_id == @member.id and timestamps[i]
        sub.update(has_unread: false, viewed_on: Time.at(timestamps[i] + 1))
      end
    end
    render_json_status(true)
  end

  def item_count
    render json: count_items(unread: false)
  end

  def unread_count
    render json: count_items(unread: true)
  end

  def subs
    limit = (params[:limit] || 0).to_i
    from_id = (params[:from_id] || 0).to_i
    items = []
    subscriptions = @member.subscriptions
    subscriptions = subscriptions.has_unread if params[:unread].to_i != 0
    subscriptions.order("subscriptions.id").includes(:folder, { feed: %i[crawl_status favicon] }).with_unread_count.each do |sub|
      unread_count = sub.unread_count.to_i
      next if params[:unread].to_i > 0 and unread_count == 0
      next if sub.id < from_id

      feed = sub.feed
      modified_on = feed.modified_on
      item = {
        subscribe_id: sub.id,
        unread_count: [unread_count, Settings.max_unread_count].min,
        folder: (sub.folder ? sub.folder.name : "").utf8_roundtrip.html_escape,
        tags: [],
        rate: sub.rate,
        public: sub.public ? 1 : 0,

        link: feed.link&.html_escape,
        feedlink: feed.feedlink.html_escape,
        title: feed.title.utf8_roundtrip.html_escape,
        icon: feed.favicon.try(:image)&.blank? ? "/img/icon/default.png" : favicon_path(feed.id),
        modified_on: modified_on ? modified_on.to_time.to_i : 0,
        subscribers_count: feed.subscribers_count
      }
      item[:ignore_notify] = 1 if sub.ignore_notify
      items << item
      break if limit > 0 and limit <= items.size
    end
    render json: items
  end

  def lite_subs
    items = []
    @member.subscriptions.includes(:folder, { feed: :favicon }).each do |sub|
      feed = sub.feed
      modified_on = feed.modified_on
      item = {
        subscribe_id: sub.id,
        folder: (sub.folder ? sub.folder.name : "").utf8_roundtrip.html_escape,
        rate: sub.rate,
        public: sub.public ? 1 : 0,
        link: feed.link.html_escape,
        feedlink: feed.feedlink.html_escape,
        title: feed.title.utf8_roundtrip.html_escape,
        icon: feed.favicon.try(:image)&.blank? ? "/img/icon/default.png" : favicon_path(feed.id),
        modified_on: modified_on ? modified_on.to_time.to_i : 0,
        subscribers_count: feed.subscribers_count
      }
      item[:ignore_notify] = 1 if sub.ignore_notify
      items << item
    end
    render json: items
  end

  def error_subs; end

  def folders
    names = []
    name2id = {}
    @member.folders.each do |folder|
      name = (folder.name || "").utf8_roundtrip.html_escape
      names << name
      name2id[name] = folder.id
    end
    render json: {
      names: names,
      name2id: name2id
    }
  end

  def crawl
    success = false
    params[:subscribe_id].to_s.split(/\s*,\s*/).each_with_index do |id, _i|
      if sub = Subscription.find(id) and sub.member_id == @member.id
        success = sub.feed.crawl
      end
    end
    render json: { a: success }
  end

  protected

  def find_sub
    @id = (params[:subscribe_id] || params[:id] || 0).to_i
    unless @sub = @member.subscriptions.includes(:feed).find_by(id: @id)
      head :not_found
      return false
    end
    true
  end

  def count_items(options = {})
    subscriptions = @member.subscriptions.includes(:feed)
    subscriptions = subscriptions.has_unread if options[:unread]
    subs_array = subscriptions.order("id").to_a
    feed_ids = subs_array.map(&:feed_id)

    items_by_feed = {}
    if feed_ids.any?
      # Use window function to limit items per feed in a single query
      max_items = Settings.max_unread_count
      sql = <<~SQL.squish
        SELECT feed_id, stored_on FROM (
          SELECT feed_id, stored_on,
                 ROW_NUMBER() OVER (PARTITION BY feed_id ORDER BY stored_on DESC) as rn
          FROM items
          WHERE feed_id IN (#{feed_ids.map { '?' }.join(',')})
        ) ranked
        WHERE rn <= ?
      SQL

      rows = Item.connection.select_rows(Item.sanitize_sql_array([sql, *feed_ids, max_items]))
      items_by_feed = rows.group_by(&:first).transform_values { |r| r.map { |row| Time.zone.parse(row[1]) } }
    end

    stored_on_list = subs_array.map do |sub|
      {
        subscription: sub,
        stored_on: items_by_feed[sub.feed_id] || []
      }
    end
    counts = []
    params[:since].split(',').each do |s|
      param_since = /^\d+$/.match?(s) ? Time.new(s.to_i) : Time.parse(s)
      counts << stored_on_list.inject(0) do |sum, pair|
        since = options[:unread] ? [param_since, pair[:subscription].viewed_on.to_time].max : param_since
        sum + pair[:stored_on].find_all { |stored_on| stored_on > since }.size
      end
    end
    return counts[0] if counts.size == 1

    counts
  end
end
