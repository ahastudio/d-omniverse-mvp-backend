require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
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
