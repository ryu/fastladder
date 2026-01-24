# frozen_string_literal: true

class Api::SubscriptionsController < ApplicationController
  include BulkSubscriptionUpdates

  before_action :login_required_api
  skip_before_action :verify_authenticity_token

  # GET /api/subscriptions/:id (alias: /api/feed/subscribed)
  def show
    sub = find_subscription
    return render_json_status(false) unless sub

    render json: {
      ApiKey: session[:session_id],
      subscribe_id: sub.id,
      folder_id: sub.folder_id || 0,
      rate: sub.rate,
      public: sub.public ? 1 : 0,
      ignore_notify: sub.ignore_notify ? 1 : 0,
      created_on: sub.created_on.to_time.to_i
    }
  end

  # POST /api/subscriptions (alias: /api/feed/subscribe)
  def create
    feedlink = params[:feedlink]
    return render_json_status(false) if feedlink.blank?

    options = build_subscription_options
    return render_json_status(false) unless options

    sub = @member.subscribe_feed(feedlink, options)
    return render_json_status(false) unless sub

    render_json_status(true, subscribe_id: sub.id)
  end

  # PATCH /api/subscriptions/:id (alias: /api/feed/update)
  def update
    sub = find_subscription_by_id
    return render_json_status(false) unless sub

    sub.apply_settings(
      rate: params[:rate]&.to_i,
      is_public: parse_boolean(params[:public]),
      folder_id: validated_folder_id(params[:folder_id]),
      ignore_notify: parse_boolean(params[:ignore_notify])
    )
    render_json_status(true)
  end

  # DELETE /api/subscriptions/:id (alias: /api/feed/unsubscribe)
  def destroy
    sub = find_subscription_by_id
    return render_json_status(false) unless sub

    subscription_id = sub.id
    sub.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("subscription-#{subscription_id}")
      end
      format.json { render_json_status(true) }
      format.any { render_json_status(true) }
    end
  end

  private

  def build_subscription_options
    options = {
      folder_id: 0,
      rate: 0,
      public: @member.default_public
    }

    if params[:folder_id].present?
      folder_id = params[:folder_id].to_i
      return nil unless @member.folders.exists?(folder_id)

      options[:folder_id] = folder_id
    end

    options[:rate] = params[:rate].to_i if params[:rate].present? && (0..5).cover?(params[:rate].to_i)

    options[:public] = params[:public].to_i != 0 if params[:public].present?

    options
  end

  def find_subscription
    sub_id = (params[:subscribe_id] || params[:id] || 0).to_i

    if sub_id.positive?
      @member.subscriptions.find_by(id: sub_id) || @member.subscriptions.find_by(feed_id: sub_id)
    elsif params[:feedlink].present?
      feed = Feed.find_by(feedlink: params[:feedlink])
      @member.subscriptions.find_by(feed_id: feed&.id)
    end
  end

  def find_subscription_by_id
    sub_id = (params[:subscribe_id] || params[:id] || 0).to_i
    return nil unless sub_id.positive?

    @member.subscriptions.find_by(id: sub_id)
  end
end
