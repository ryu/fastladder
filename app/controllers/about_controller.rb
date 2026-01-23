class AboutController < ApplicationController
  def index
    url = url_from_path(:url) if params[:url].present?
    @feed = Feed.find_by(feedlink: url) if url.present?
    if @feed.nil?
      respond_to do |format|
        format.html { render file: "#{Rails.public_path.join('404.html')}", status: :not_found }
        format.json { render json: @feed.to_json } # for backward compatibility
        format.any { head :not_found }
      end
    else
      @is_feedlink = true
      respond_to do |format|
        format.html { render action: :index }
        format.json { render json: @feed.to_json }
      end
    end
  end
end
