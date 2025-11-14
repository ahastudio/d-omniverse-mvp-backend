require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "GET /posts" do
    get posts_url, as: :json

    assert_response :ok

    assert_match posts(:text_only_update).id, response.body
    assert_match posts(:text_only_update).content, response.body
  end

  test "GET /posts?type=video" do
    get posts_url(type: "video"), as: :json

    assert_response :ok

    assert_match posts(:admin_update).id, response.body
    refute_match posts(:text_only_update).id, response.body
  end

  test "POST /posts" do
    user = users(:admin)
    token = user.generate_token

    post posts_url,
         params: { content: "New post content" },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :created

    assert_match "New post content", response.body
  end

  test "POST /posts - with video URL" do
    user = users(:dancer)
    token = user.generate_token

    post posts_url,
         params: {
           content: "Video post",
           videoUrl: "https://example.com/video.mp4"
         },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :created

    assert_match "Video post", response.body
    assert_match "https://example.com/video.mp4", response.body
  end
end
