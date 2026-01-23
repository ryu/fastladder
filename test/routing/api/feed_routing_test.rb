# frozen_string_literal: true

require "test_helper"

class Api::FeedRoutingTest < ActionDispatch::IntegrationTest
  # Legacy routes now point to new RESTful controllers
  # Using assert_recognizes for legacy routes (tests recognition only, not generation)
  # These routes are for backward compatibility - they recognize old paths
  # but new paths are generated via the RESTful resource routes

  test "routes discover via GET to discoveries#create" do
    assert_recognizes(
      { controller: "api/feed/discoveries", action: "create" },
      { method: "get", path: "/api/feed/discover" }
    )
  end

  test "routes discover via POST to discoveries#create" do
    assert_recognizes(
      { controller: "api/feed/discoveries", action: "create" },
      { method: "post", path: "/api/feed/discover" }
    )
  end

  test "routes subscribed via GET to subscriptions#show" do
    assert_recognizes(
      { controller: "api/subscriptions", action: "show" },
      { method: "get", path: "/api/feed/subscribed" }
    )
  end

  test "routes subscribed via POST to subscriptions#show" do
    assert_recognizes(
      { controller: "api/subscriptions", action: "show" },
      { method: "post", path: "/api/feed/subscribed" }
    )
  end

  test "routes subscribe to subscriptions#create" do
    assert_recognizes(
      { controller: "api/subscriptions", action: "create" },
      { method: "post", path: "/api/feed/subscribe" }
    )
  end

  test "routes unsubscribe to subscriptions#destroy" do
    assert_recognizes(
      { controller: "api/subscriptions", action: "destroy" },
      { method: "post", path: "/api/feed/unsubscribe" }
    )
  end

  test "routes update to subscriptions#update" do
    assert_recognizes(
      { controller: "api/subscriptions", action: "update" },
      { method: "post", path: "/api/feed/update" }
    )
  end

  test "routes move to subscriptions/folders#update" do
    assert_recognizes(
      { controller: "api/subscriptions/folders", action: "update" },
      { method: "post", path: "/api/feed/move" }
    )
  end

  test "routes set_rate to subscriptions/rates#update" do
    assert_recognizes(
      { controller: "api/subscriptions/rates", action: "update" },
      { method: "post", path: "/api/feed/set_rate" }
    )
  end

  test "routes set_notify to subscriptions/notifications#update" do
    assert_recognizes(
      { controller: "api/subscriptions/notifications", action: "update" },
      { method: "post", path: "/api/feed/set_notify" }
    )
  end

  test "routes set_public to subscriptions/visibilities#update" do
    assert_recognizes(
      { controller: "api/subscriptions/visibilities", action: "update" },
      { method: "post", path: "/api/feed/set_public" }
    )
  end

  test "routes fetch_favicon to feed/favicons#create" do
    assert_recognizes(
      { controller: "api/feed/favicons", action: "create" },
      { method: "post", path: "/api/feed/fetch_favicon" }
    )
  end

  # add_tags and remove_tags still use the old controller (not yet migrated)
  %w[add_tags remove_tags].each do |name|
    test "routes #{name} to feed##{name}" do
      assert_routing(
        { method: "post", path: "/api/feed/#{name}" },
        { controller: "api/feed", action: name }
      )
    end
  end
end
