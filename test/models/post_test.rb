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

  test "creation - with parent" do
    user = users(:admin)
    parent = posts(:parent_post)
    post = user.posts.create!(
      id: ULID.generate,
      content: "Reply content",
      parent: parent
    )
    assert post.persisted?
    assert_equal parent.id, post.parent_id
  end

  test "cannot be own parent" do
    post = posts(:text_only_update)
    post.parent_id = post.id

    assert_not post.valid?
    assert_includes post.errors[:parent_id], "cannot be self"
  end

  test "parent must exist" do
    post = Post.new(
      user: users(:admin),
      content: "Reply to non-existent post",
      parent_id: "01NONEXISTENT00000000000"
    )

    assert_not post.valid?
    assert_includes post.errors[:parent_id], "does not exist"
  end

  test "can reply to soft-deleted parent" do
    deleted_parent = posts(:deleted_post)
    post = Post.new(
      user: users(:admin),
      content: "Reply to deleted post",
      parent_id: deleted_parent.id
    )

    assert post.valid?
  end

  test "soft delete" do
    post = posts(:text_only_update)

    assert_nil post.deleted_at
    assert_not post.deleted?

    post.soft_delete!

    assert_not_nil post.deleted_at
    assert post.deleted?
  end

  test "soft delete decrements parent replies_count" do
    parent = posts(:parent_post)
    child = posts(:child_post)

    initial_count = parent.replies_count
    child.soft_delete!

    assert_equal initial_count - 1, parent.reload.replies_count
  end

  test "soft delete idempotent - does not decrement twice" do
    parent = posts(:parent_post)
    child = posts(:child_post)

    initial_count = parent.replies_count
    child.soft_delete!
    child.soft_delete!

    assert_equal initial_count - 1, parent.reload.replies_count
  end

  test "ancestors" do
    child = posts(:child_post)
    parent = posts(:parent_post)

    assert_equal [ parent ], child.ancestors
  end

  test "replies" do
    parent = posts(:parent_post)
    child = posts(:child_post)

    assert_includes parent.replies, child
  end

  test "visible scope excludes deleted posts" do
    assert_includes Post.visible, posts(:text_only_update)
    assert_not_includes Post.visible, posts(:deleted_post)
  end
end
