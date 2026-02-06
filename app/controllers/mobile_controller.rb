# frozen_string_literal: true

class MobileController < ApplicationController # rubocop:todo Style/Documentation
  before_action :login_required

  def index
    @subscriptions = current_member.subscriptions.includes(:feed).has_unread.order('rate desc').with_unread_count.select do
      _1.unread_count.positive?
    end
  end

  def read_feed
    @subscription = current_member.subscriptions.find_by(id: params[:feed_id])
    unless @subscription
      render plain: "Not Found", status: :not_found
      return
    end
    @items = @subscription.feed.items.stored_since(@subscription.viewed_on).order('stored_on asc').limit(200)
  end

  def mark_as_read
    @subscription = current_member.subscriptions.find_by(id: params[:feed_id])
    unless @subscription
      render plain: "Not Found", status: :not_found
      return
    end
    @subscription.update!(has_unread: false, viewed_on: Time.at(params[:timestamp].to_i + 1))

    redirect_to '/mobile'
  end

  def pin
    item = Item.find_by(id: params[:item_id])
    unless item
      redirect_to '/mobile', alert: 'Item not found'
      return
    end

    subscription = current_member.subscriptions.find_by(feed_id: item.feed_id)
    unless subscription
      redirect_to '/mobile', alert: 'Access denied'
      return
    end

    begin
      current_member.pins.create!(link: item.link, title: item.title)
    rescue ActiveRecord::RecordNotUnique
    end

    redirect_to "/mobile/#{subscription.id}#item-#{item.id}"
  end
end
