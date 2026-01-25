# frozen_string_literal: true

class Api::Subscriptions::FoldersController < ApplicationController
  include BulkSubscriptionUpdates

  before_action :login_required_api
  skip_before_action :verify_authenticity_token

  # PATCH /api/subscriptions/folders (alias: /api/feed/move)
  # Bulk move subscriptions to a folder
  def update
    folder = @member.find_folder_by_name_or_id(params[:to])
    subscription_ids = parse_subscription_ids
    member_subscriptions(subscription_ids).update_all(folder_id: folder&.id)

    folder_name = folder&.name || ""

    if turbo_stream_request?
      streams = subscription_ids.map do |id|
        turbo_stream.replace(
          "subscription-folder-#{id}",
          html: %(<span class="folder-name">#{ERB::Util.html_escape(folder_name)}</span>)
        )
      end
      render turbo_stream: streams
    else
      render_json_status(true)
    end
  end
end
