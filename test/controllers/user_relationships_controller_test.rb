require "test_helper"

class UserRelationshipsControllerTest < ActionDispatch::IntegrationTest
  test "POST /user-relationships - profile_view" do
    user = users(:admin)
    target = users(:dancer)
    token = user.generate_token

    post user_relationships_url,
         params: { targetUserId: target.id, type: "profile_view" },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :created

    data = JSON.parse(response.body)
    assert_equal user.id, data["userId"]
    assert_equal target.id, data["targetUserId"]
    assert_equal 6, data["score"]
  end

  test "POST /user-relationships - reaction" do
    user = users(:dancer)
    target = users(:admin)
    token = user.generate_token

    post user_relationships_url,
         params: { targetUserId: target.id, type: "reaction" },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :created

    data = JSON.parse(response.body)
    assert_equal 2, data["score"]
  end

  test "POST /user-relationships - post_view" do
    user = users(:dancer)
    target = users(:admin)
    token = user.generate_token

    post user_relationships_url,
         params: { targetUserId: target.id, type: "post_view" },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :created

    data = JSON.parse(response.body)
    assert_equal 1, data["score"]
  end

  test "POST /user-relationships - invalid type" do
    user = users(:admin)
    target = users(:dancer)
    token = user.generate_token

    post user_relationships_url,
         params: { targetUserId: target.id, type: "invalid_type" },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :unprocessable_entity
  end

  test "POST /user-relationships - self targeting" do
    user = users(:admin)
    token = user.generate_token

    post user_relationships_url,
         params: { targetUserId: user.id, type: "profile_view" },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :unprocessable_entity
  end

  test "POST /user-relationships - target not found" do
    user = users(:admin)
    token = user.generate_token

    post user_relationships_url,
         params: { targetUserId: "nonexistent", type: "profile_view" },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :not_found
  end

  test "POST /user-relationships - unauthorized" do
    target = users(:dancer)

    post user_relationships_url,
         params: { targetUserId: target.id, type: "profile_view" },
         as: :json

    assert_response :unauthorized
  end

  test "GET /user-relationships/:id - existing relationship" do
    user = users(:admin)
    target = users(:dancer)
    token = user.generate_token

    get user_relationship_url(target.id),
        headers: { "Authorization": "Bearer #{token}" },
        as: :json

    assert_response :ok

    data = JSON.parse(response.body)
    assert_equal 5, data["score"]
  end

  test "GET /user-relationships/:id - no relationship" do
    user = users(:dancer)
    target = users(:admin)
    token = user.generate_token

    get user_relationship_url(target.id),
        headers: { "Authorization": "Bearer #{token}" },
        as: :json

    assert_response :ok

    data = JSON.parse(response.body)
    assert_equal 0, data["score"]
  end

  test "GET /user-relationships/:id - unauthorized" do
    target = users(:dancer)

    get user_relationship_url(target.id), as: :json

    assert_response :unauthorized
  end

  test "GET /user-relationships/:id - target not found" do
    user = users(:admin)
    token = user.generate_token

    get user_relationship_url("nonexistent"),
        headers: { "Authorization": "Bearer #{token}" },
        as: :json

    assert_response :not_found
  end

  test "POST /user-relationships - score accumulates" do
    user = users(:admin)
    target = users(:dancer)
    token = user.generate_token

    3.times do
      post user_relationships_url,
           params: { targetUserId: target.id, type: "profile_view" },
           headers: { "Authorization": "Bearer #{token}" },
           as: :json

      assert_response :created
    end

    data = JSON.parse(response.body)
    assert_equal 8, data["score"]
  end
end
