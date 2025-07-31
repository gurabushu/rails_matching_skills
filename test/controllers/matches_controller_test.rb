require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      skill: "Web Development",
      description: "Test description"
    )
  end

  test "matches index requires authentication" do
    get matches_url
    assert_response :redirect
  end
end
