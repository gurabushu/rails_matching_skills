require "test_helper"

class DealsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      skill: "Web Development",
      description: "Test description"
    )
  end

  test "deals index requires authentication" do
    get deals_url
    assert_response :redirect
  end
end
