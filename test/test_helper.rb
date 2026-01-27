# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"

  add_group "Controllers", "app/controllers"
  add_group "Models", "app/models"
  add_group "Helpers", "app/helpers"
  add_group "Libraries", "lib"

  # Enable coverage merging across test runs
  enable_coverage :branch
  primary_coverage :line

  # Track all test runs
  command_name "rails-#{$$}"
  merge_timeout 3600
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

require "minitest/autorun"
require "minitest/spec"
require "minitest/retry"
# FactoryBot removed - using fixtures and TestDataHelper instead
require "webmock/minitest"
require "fastladder/crawler"

Minitest::Retry.use!(retry_count: 15) if ENV["CI"]

WebMock.enable!
WebMock.disable_net_connect!(allow_localhost: true)

Rails.root.glob("test/support/**/*.rb").each { |f| require f }

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include TestDataHelper

    # Add more helper methods to be used by all tests here...
  end
end
