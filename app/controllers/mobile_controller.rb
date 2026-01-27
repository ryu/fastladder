# frozen_string_literal: true

class MobileController < ApplicationController
  before_action :login_required
  layout false

  def index
    @subscriptions = current_member.subscriptions.includes(:feed).has_unread.order(rate: :desc).with_unread_count.select do
      it.unread_count.positive?
    end
  end

  def pins
    @pins = current_member.pins.order(created_on: :desc)
  end

  def remove_pin
    pin = current_member.pins.find_by(id: params[:pin_id])

    if pin&.destroy
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove("pin-#{params[:pin_id]}") }
        format.json { render json: { success: true } }
        format.html { redirect_to "/pins" }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false } }
        format.html { redirect_to "/pins" }
      end
    end
  end

  def read_feed
    @subscription = Subscription.find(params[:feed_id])
    @items = @subscription.feed.items.stored_since(@subscription.viewed_on).order(:stored_on).limit(200)
  end

  def mark_as_read
    @subscription = Subscription.find(params[:feed_id])
    @subscription.update!(has_unread: false, viewed_on: Time.zone.at(params[:timestamp].to_i + 1))

    respond_to do |format|
      format.json { render json: { success: true, redirect_to: "/mobile" } }
      format.html { redirect_to "/mobile" }
    end
  end

  def pin
    item = Item.find(params[:item_id])
    already_pinned = false

    begin
      current_member.pins.create!(link: item.link, title: item.title)
    rescue ActiveRecord::RecordNotUnique
      already_pinned = true
    end

    respond_to do |format|
      format.json { render json: { success: true, already_pinned: already_pinned } }
      format.html { redirect_to "/mobile/#{item.feed_id}#item-#{item.id}" }
    end
  end
end
