require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  def setup
    # テストデータを作成
    @user1 = User.create!(
      name: "Test User 1",
      email: "test1@example.com", 
      password: "password123",
      skill: "Web Development",
      description: "Test description 1"
    )
    
    @user2 = User.create!(
      name: "Test User 2",
      email: "test2@example.com",
      password: "password123", 
      skill: "Mobile Development",
      description: "Test description 2"
    )
  end

  test "should get index" do
    get stats_index_url
    assert_response :success
    assert_not_nil assigns(:stats)
  end
end
