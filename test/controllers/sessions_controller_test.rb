require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "POST /session - with valid credentials" do
    post session_url, params: {
      username: "dancer",
      password: "password123"
    }, as: :json

    assert_response :created

    response_json = JSON.parse(response.body)
    token = response_json["accessToken"]

    payload = JWT.decode(
      token,
      Rails.application.secret_key_base,
      true,
      { algorithm: "HS256" }
    ).first

    assert_equal "dancer", payload["username"]
  end

  test "POST /session - with invalid username" do
    post session_url, params: {
      username: "wrong-user",
      password: "password123"
    }, as: :json

    assert_response :unauthorized

    assert_match "Invalid username or password", response.body
  end

  test "POST /session - with invalid password" do
    post session_url, params: {
      username: "dancer",
      password: "wrong-password"
    }, as: :json

    assert_response :unauthorized

    assert_match "Invalid username or password", response.body
  end
end
