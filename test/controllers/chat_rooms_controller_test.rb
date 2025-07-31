require "test_helper"

class ChatRoomsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      skill: "Web Development",
      description: "Test description"
    )
  end

  test "chat rooms index requires authentication" do
    get chat_rooms_url
    assert_response :redirect
  end
end
