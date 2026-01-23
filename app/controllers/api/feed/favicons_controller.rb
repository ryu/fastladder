# frozen_string_literal: true

class Api::Feed::FaviconsController < ApplicationController
  before_action :login_required_api
  skip_before_action :verify_authenticity_token

  # POST /api/feed/favicons (alias: /api/feed/fetch_favicon)
  def create
    feedlink = params[:feedlink]
    return render_json_status(false) if feedlink.blank?

    feed = Feed.find_by(feedlink: feedlink)
    return render_json_status(false) unless feed

    feed.fetch_favicon!
    render_json_status(true)
  end
end
