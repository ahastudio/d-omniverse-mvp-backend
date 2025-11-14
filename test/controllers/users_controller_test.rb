require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "GET /users/:username" do
    user = users(:admin)

    get user_url(user.username), as: :json

    assert_response :ok

    assert_match user.username, response.body
    assert_match user.nickname, response.body
  end

  test "GET /users/:username - not found" do
    get user_url("nonexistent"), as: :json

    assert_response :not_found

    assert_match "User not found", response.body
  end

  test "POST /users" do
    assert_difference("User.count") do
      post users_url, params: {
        username: "newuser",
        password: "password123",
        name: "New User",
        phoneNumber: "010-9999-8888"
      }, as: :json
    end

    assert_response :created

    assert_match "accessToken", response.body
  end

  test "POST /users - with invalid data" do
    assert_no_difference("User.count") do
      post users_url, params: {
        username: "",
        password: "password123"
      }, as: :json
    end

    assert_response :unprocessable_entity

    assert_match "errors", response.body
  end
end
