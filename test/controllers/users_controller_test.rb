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

  test "guest login creates guest user and signs in" do
    assert_difference('User.count', 1) do
      post '/users/guest_sign_in'
    end
    
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    
    # ゲストユーザーが作成されたことを確認
    guest_user = User.find_by(email: 'guest@example.com')
    assert_not_nil guest_user
    assert_equal 'ゲストユーザー', guest_user.name
    assert guest_user.guest_user?
  end

  test "guest login reuses existing guest user" do
    # 既存のゲストユーザーを作成
    existing_guest = User.create!(
      name: 'ゲストユーザー',
      email: 'guest@example.com',
      password: 'password123'
    )
    
    assert_no_difference('User.count') do
      post '/users/guest_sign_in'
    end
    
    assert_redirected_to root_path
  end
end
