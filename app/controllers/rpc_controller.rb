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

  # TODO: Fix Baaaaaad SQL
  def update_feeds
    JSON.parse(params[:feeds]).each do |options|
      options.symbolize_keys!
      create_item options, @member
    end
    render json: { result: true }
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
