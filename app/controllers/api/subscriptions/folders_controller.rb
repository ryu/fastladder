# frozen_string_literal: true

class Api::Subscriptions::FoldersController < ApplicationController
  include BulkSubscriptionUpdates

  before_action :login_required_api
  skip_before_action :verify_authenticity_token

  # PATCH /api/subscriptions/folders (alias: /api/feed/move)
  # Bulk move subscriptions to a folder
  def update
    folder = @member.find_folder_by_name_or_id(params[:to])
    member_subscriptions(parse_subscription_ids).update_all(folder_id: folder&.id)
    render_json_status(true)
  end
end
