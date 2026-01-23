# frozen_string_literal: true

class Api::FeedController < ApplicationController
  before_action :login_required_api
  skip_before_action :verify_authenticity_token

  # These actions are not yet migrated to RESTful controllers
  def add_tags
    # TODO: Implement tag management
  end

  def remove_tags
    # TODO: Implement tag management
  end
end
