require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "creation" do
    user = User.create!(
      id: ULID.generate,
      username: "tester",
      password: "password123",
      name: "Test User",
      phone_number: "010-5555-6666",
      nickname: "Tester",
      bio: "Test user biography",
      avatar_url: "https://example.com/test.jpg"
    )
    assert user.persisted?
  end

  test "authenticate with correct password" do
    user = users(:admin)
    assert user.authenticate("password123")
  end

  test "authenticate with wrong password" do
    user = users(:admin)
    assert_not user.authenticate("wrong-password")
  end

  test "password change" do
    user = users(:admin)
    user.password = "newpassword456"
    user.save!

    assert user.authenticate("newpassword456")
    assert_not user.authenticate("password123")
  end

  test "password cannot be set to empty string" do
    user = users(:admin)

    user.password = ""

    assert_raises(ActiveRecord::RecordInvalid) do
      user.save!
    end
  end
end
