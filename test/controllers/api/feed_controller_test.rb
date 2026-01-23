# frozen_string_literal: true

require "test_helper"

class Api::FeedControllerTest < ActionController::TestCase
  def setup
    @member = create_member(password: "test", password_confirmation: "test")
  end

  # add_tags and remove_tags are the only remaining actions on this controller
  # Other actions have been moved to RESTful controllers:
  # - discover -> Api::Feed::DiscoveriesController#create
  # - subscribe/unsubscribe/subscribed/update -> Api::SubscriptionsController
  # - set_rate -> Api::Subscriptions::RatesController#update
  # - set_notify -> Api::Subscriptions::NotificationsController#update
  # - set_public -> Api::Subscriptions::VisibilitiesController#update
  # - move -> Api::Subscriptions::FoldersController#update
  # - fetch_favicon -> Api::Feed::FaviconsController#create

  test "POST add_tags renders response" do
    post :add_tags, session: { member_id: @member.id }
    assert_response :success
  end

  test "POST remove_tags renders response" do
    post :remove_tags, session: { member_id: @member.id }
    assert_response :success
  end

  test "add_tags requires login" do
    post :add_tags
    assert response.body.blank?
  end

  test "remove_tags requires login" do
    post :remove_tags
    assert response.body.blank?
  end
end
