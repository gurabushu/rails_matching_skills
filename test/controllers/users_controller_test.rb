require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      skill: "Web Development",
      description: "Test description"
    )
  end

  test "users index allows guest access" do
    get users_url
    assert_response :success
  end

  test "user show allows guest access" do
    get user_url(@user)
    assert_response :success
  end
end
