require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "creation" do
    user = users(:admin)
    post = user.posts.create!(
      id: ULID.generate,
      content: "Test post content"
    )
    assert post.persisted?
  end

  test "creation - with video URL" do
    user = users(:admin)
    post = user.posts.create!(
      id: ULID.generate,
      content: "Test post content",
      video_url: "https://example.com/video.mp4"
    )
    assert post.persisted?
  end
end
