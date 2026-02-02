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

  test "POST /posts - with video" do
    user = users(:dancer)
    token = user.generate_token

    video_data = File.binread(file_fixture("sample.mp4"))
    base64_data = Base64.strict_encode64(video_data)
    data_url = "data:video/mp4;base64,#{base64_data}"

    path = "/videos/hls/TESTKEY/playlist.m3u8"
    original_process_video = Post.instance_method(:process_video)
    Post.define_method(:process_video) { self.video_url = path }

    post posts_url,
         params: {
           content: "Video with base64",
           videoUrl: data_url
         },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :created

    assert_match "Video with base64", response.body
    assert_match "/videos/hls/TESTKEY/playlist.m3u8", response.body
    refute_match "data:", response.body
  ensure
    Post.define_method(:process_video, original_process_video)
  end

  test "DELETE /posts/:id" do
    user = users(:admin)
    token = user.generate_token
    post = posts(:text_only_update)

    delete post_url(post),
           headers: { "Authorization": "Bearer #{token}" },
           as: :json

    assert_response :no_content

    assert_not_nil post.reload.deleted_at
  end

  test "DELETE /posts/:id - forbidden" do
    user = users(:dancer)
    token = user.generate_token
    post = posts(:text_only_update)

    delete post_url(post),
           headers: { "Authorization": "Bearer #{token}" },
           as: :json

    assert_response :forbidden
  end

  test "DELETE /posts/:id - unauthorized" do
    post = posts(:text_only_update)

    delete post_url(post), as: :json

    assert_response :unauthorized
  end
end
