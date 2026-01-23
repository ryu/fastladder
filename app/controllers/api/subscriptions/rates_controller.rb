# frozen_string_literal: true

class Api::Subscriptions::RatesController < ApplicationController
  include BulkSubscriptionUpdates

  before_action :login_required_api
  skip_before_action :verify_authenticity_token

  # PATCH /api/subscriptions/:subscription_id/rate (alias: /api/feed/set_rate)
  def update
    sub = find_subscription
    return render_json_status(false) unless sub

    rate = params[:rate].to_i
    sub.update!(rate: rate) if (0..5).cover?(rate)
    render_json_status(true)
  end

  private

  def find_subscription
    sub_id = (params[:subscription_id] || params[:subscribe_id] || 0).to_i
    return nil unless sub_id.positive?

    @member.subscriptions.find_by(id: sub_id)
  end
end
