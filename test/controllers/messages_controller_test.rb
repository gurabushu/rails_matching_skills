require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      skill: "Web Development",
      description: "Test description"
    )
  end

  test "user authentication required for messages" do
    # Check that messages require authentication by accessing a chat room
    get chat_rooms_url
    assert_response :redirect
  end
end
