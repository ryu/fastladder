# frozen_string_literal: true

class Api::Subscriptions::VisibilitiesController < ApplicationController
  include BulkSubscriptionUpdates

  before_action :login_required_api
  skip_before_action :verify_authenticity_token

  # PATCH /api/subscriptions/visibilities (alias: /api/feed/set_public)
  # Bulk update for multiple subscriptions
  def update
    is_public = parse_boolean(params[:public])
    return render_json_status(false) if is_public.nil?

    subscription_ids = parse_subscription_ids
    member_subscriptions(subscription_ids).update_all(public: is_public)

    visibility_text = is_public ? "Public" : "Private"
    visibility_class = is_public ? "public" : "private"

    if turbo_stream_request?
      streams = subscription_ids.map do |id|
        turbo_stream.replace(
          "subscription-visibility-#{id}",
          html: %(<span class="visibility #{visibility_class}">#{visibility_text}</span>)
        )
      end
      render turbo_stream: streams
    else
      render_json_status(true)
    end
  end
end
