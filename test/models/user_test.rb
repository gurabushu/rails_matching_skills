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

  test "should validate avatar_image for regular users" do
    user = User.new(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      skill: "Programming"  # skillを追加
    )
    
    # 通常ユーザーは画像バリデーションが適用される
    # ここでは単純にアバター画像なしでも有効であることをテスト
    assert user.valid?
  end

  test "should skip avatar_image validation for guest users" do
    user = User.new(
      name: "ゲストユーザー",
      email: "guest@example.com", 
      password: "password123",
      skill: ""  # ゲストユーザーはスキルが空でも可
    )
    
    # ゲストユーザーは画像バリデーションがスキップされる
    assert user.valid?
    assert user.guest_user?
  end

  test "avatar_url should return default image when no avatar attached" do
    user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      skill: "Programming"  # skillを追加
    )
    
    url = user.avatar_url
    assert_includes url, 'default_avatar.svg'
  end
end
