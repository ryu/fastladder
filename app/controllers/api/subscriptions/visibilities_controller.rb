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

    member_subscriptions(parse_subscription_ids).update_all(public: is_public)
    render_json_status(true)
  end
end
