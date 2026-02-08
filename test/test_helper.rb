# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

require "minitest/autorun"
require "minitest/spec"
require "minitest/retry"
require "webmock/minitest"
require "fastladder/crawler"

Minitest::Retry.use!(retry_count: 15) if ENV["CI"]

WebMock.enable!
WebMock.disable_net_connect!(allow_localhost: true)

Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include RecordCreationHelper
  end
end
