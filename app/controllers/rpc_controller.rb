class RpcController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :auth
  def update_feed
    options = params.dup
    options.merge! JSON.parse(options[:json]).symbolize_keys if options[:json]
    create_item options, @member
    render json: { result: true }
  end

  def check_digest
    digests = JSON.parse(params[:digests]).uniq
    existing_digests = Item.where(digest: digests).pluck(:digest)
    render json: (digests - existing_digests)
  end

  def update_feeds
    feeds_data = JSON.parse(params[:feeds])
    return render json: { result: false, error: "No feeds provided" } if feeds_data.empty?

    created_count = 0
    errors = []

    ApplicationRecord.transaction do
      feeds_data.each_with_index do |options, index|
        options.symbolize_keys!
        create_item(options, @member)
        created_count += 1
      rescue StandardError => e
        errors << { index: index, feedlink: options[:feedlink], error: e.message }
        Rails.logger.error("RPC update_feeds error at index #{index}: #{e.message}")
      end
    end

    render json: {
      result: errors.empty?,
      created: created_count,
      errors: errors.presence
    }.compact
  end

  def export
    case params[:format]
    when 'opml'
      render xml: @member.export('opml')
    when 'json'
      render json: @member.export('json')
    else
      render 'public/404', layout: false, status: :not_found
    end
  end

  private

  def auth
    @member = Member.find_by(auth_key: params[:api_key])
    render('public/404', layout: false, status: :not_found) and return unless @member
  end

  def create_item(options, member)
    if options[:feedtitle]
      feed = Feed.find_by(feedlink: options[:feedlink])
      unless feed
        description = options[:feeddescription] || options[:feedtitle]
        feed = Feed.create(feedlink: options[:feedlink], title: options[:feedtitle], link: options[:feedlink], description: description)
      end
      sub = member.subscriptions.find_by(feed_id: feed.id)
      sub ||= member.subscriptions.create(feed_id: feed.id, has_unread: true)
    else
      sub = member.subscribe_feed options[:feedlink]
    end
    item =
      if options[:guid]
        Item.find_or_create_by(guid: options[:guid], feed_id: sub.feed.id) do |item|
          item.link = options[:link]
        end
      else
        Item.find_or_create_by(link: options[:link], feed_id: sub.feed.id) do |item|
          item.guid = item.link
        end
      end
    sub.update!(has_unread: true)
    item.title = options[:title]
    item.body = options[:body]
    item.author = options[:author]
    item.category = options[:category]
    item.modified_on = options[:published_date]
    item.save
  end
end
