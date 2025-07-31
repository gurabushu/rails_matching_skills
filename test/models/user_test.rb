require "test_helper"

class UserTest < ActiveSupport::TestCase
  # fixtureをスキップ
  self.use_instantiated_fixtures = false
  self.use_transactional_tests = true

  test "should be valid with valid attributes" do
    user = User.new(
      name: "Test User",
      email: "test@example.com",
      skill: "Programming",
      description: "Test description",
      password: "password"
    )
    assert user.valid?
  end

  test "should require name" do
    user = User.new(
      email: "test@example.com",
      skill: "Programming",
      password: "password"
    )
    assert_not user.valid?
  end

  test "should require email" do
    user = User.new(
      name: "Test User",
      skill: "Programming",
      password: "password"
    )
    assert_not user.valid?
  end

  test "guest_user? should return true for guest user" do
    user = User.new(email: 'guest@example.com')
    assert user.guest_user?
  end

  test "guest_user? should return false for regular user" do
    user = User.new(email: 'regular@example.com')
    assert_not user.guest_user?
  end
end
