# frozen_string_literal: true

class Api::Subscriptions::NotificationsController < ApplicationController
  include BulkSubscriptionUpdates

  before_action :login_required_api
  skip_before_action :verify_authenticity_token

  # PATCH /api/subscriptions/notifications (alias: /api/feed/set_notify)
  # Bulk update for multiple subscriptions
  def update
    ignore = parse_boolean(params[:ignore])
    return render_json_status(false) if ignore.nil?

    member_subscriptions(parse_subscription_ids).update_all(ignore_notify: ignore)
    render_json_status(true)
  end
end
