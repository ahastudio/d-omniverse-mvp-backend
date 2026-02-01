require "test_helper"

class UsernameSeatsControllerTest < ActionDispatch::IntegrationTest
  test "사용 가능한 username은 200 OK 응답" do
    get username_seat_url(username: "validuser123")

    assert_response :ok
  end

  test "이미 존재하는 username은 409 Conflict 응답" do
    user = users(:admin)

    get username_seat_url(username: user.username)

    assert_response :conflict
  end

  test "대소문자 혼합 username은 소문자로 변환하여 검사" do
    user = users(:admin)

    get username_seat_url(username: user.username.upcase)

    assert_response :conflict
  end

  test "특수 문자가 포함된 username" do
    get username_seat_url(username: "user@123")

    assert_response :bad_request
  end

  test "공백이 포함된 username" do
    get username_seat_url(username: "user name")

    assert_response :bad_request
  end

  test "매우 짧은 username (2자)" do
    get username_seat_url(username: "ab")

    assert_response :bad_request
  end

  test "매우 긴 username" do
    long_username = "a" * 101

    get username_seat_url(username: long_username)

    assert_response :bad_request
  end

  test "숫자로 시작하는 username" do
    get username_seat_url(username: "123user")

    assert_response :bad_request
  end

  test "빈 username은 라우팅 오류 404" do
    get "/username_seats/"

    assert_response :not_found
  end
end
