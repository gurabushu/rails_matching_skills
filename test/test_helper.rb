ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Devise test helpers configuration
Devise.stretches = 1

class ActiveSupport::TestCase
  # Use factories instead of all fixtures to avoid complex foreign key violations
  # fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  def setup
    # Clear any previous user sessions
    logout
  end
  
  def teardown
    logout
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
