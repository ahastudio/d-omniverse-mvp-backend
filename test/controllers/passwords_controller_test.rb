require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:dancer)
    @token = @user.generate_token
    @auth_header = { "Authorization" => "Bearer #{@token}" }
  end

  test "올바른 기존 패스워드로 변경 성공" do
    patch user_password_url(user_username: @user.username),
          params: { oldPassword: "password123", newPassword: "newpass456" },
          headers: @auth_header,
          as: :json

    assert_response :ok

    @user.reload
    assert @user.authenticate("newpass456")
  end

  test "잘못된 기존 패스워드로 변경 실패" do
    patch user_password_url(user_username: @user.username),
          params: { oldPassword: "wrongpass", newPassword: "newpass456" },
          headers: @auth_header,
          as: :json

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "Invalid current password", json["error"]
  end

  test "기존 패스워드 누락 시 422 응답" do
    patch user_password_url(user_username: @user.username),
          params: { newPassword: "newpass456" },
          headers: @auth_header,
          as: :json

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "Invalid current password", json["error"]
  end

  test "인증 없이 요청 시 401 응답" do
    patch user_password_url(user_username: @user.username),
          params: { oldPassword: "password123", newPassword: "newpass456" },
          as: :json

    assert_response :unauthorized
  end

  test "다른 사용자 패스워드 변경 시 403 응답" do
    other_user = users(:admin)

    patch user_password_url(user_username: other_user.username),
          params: { oldPassword: "password123", newPassword: "newpass456" },
          headers: @auth_header,
          as: :json

    assert_response :forbidden
  end

  test "존재하지 않는 사용자 패스워드 변경 시 404 응답" do
    patch user_password_url(user_username: "nonexistent"),
          params: { oldPassword: "password123", newPassword: "newpass456" },
          headers: @auth_header,
          as: :json

    assert_response :not_found
  end

  test "대소문자 섞인 username으로 변경 성공" do
    patch user_password_url(user_username: @user.username.upcase),
          params: { oldPassword: "password123", newPassword: "newpass456" },
          headers: @auth_header,
          as: :json

    assert_response :ok

    @user.reload
    assert @user.authenticate("newpass456")
  end

  test "새 패스워드가 빈 문자열이면 422 응답" do
    patch user_password_url(user_username: @user.username),
          params: { oldPassword: "password123", newPassword: "" },
          headers: @auth_header,
          as: :json

    assert_response :unprocessable_entity
  end

  test "새 패스워드가 기존과 동일해도 성공" do
    patch user_password_url(user_username: @user.username),
          params: { oldPassword: "password123", newPassword: "password123" },
          headers: @auth_header,
          as: :json

    assert_response :ok

    @user.reload
    assert @user.authenticate("password123")
  end
end
