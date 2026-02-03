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

  test "duplicate post prevention within 10 seconds" do
    user = users(:admin)
    content = "Duplicate content test"

    first_post = user.posts.create!(
      id: ULID.generate,
      content: content
    )
    assert first_post.persisted?

    duplicate_post = user.posts.new(
      id: ULID.generate,
      content: content
    )
    assert_not duplicate_post.valid?
    assert_includes duplicate_post.errors[:base],
                    "Duplicate post detected"
  end
end
