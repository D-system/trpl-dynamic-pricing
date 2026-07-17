ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

require "simplecov"
SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
  # TODO: update to `branch: 100` when more tests added
  minimum_coverage line: 100, branch: 92.85
end

require "webmock/minitest"
WebMock.disable_net_connect!

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: 1)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
