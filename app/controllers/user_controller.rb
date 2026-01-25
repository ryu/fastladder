class UserController < ApplicationController
  def index
    @target_member = Member.find_by(username: params[:login_name])
    @subscriptions = @target_member.subscriptions.includes(:feed).where(public: true).order("created_on DESC").limit(30) if @target_member.public
    respond_to do |format|
      format.html
      format.rss { render layout: false }
      format.opml { render layout: false }
    end
  end
end
