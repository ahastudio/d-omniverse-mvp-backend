class Post < ApplicationRecord
  include VideoProcessable

  video_attribute :video_url

  belongs_to :user

  scope :visible, -> { where(deleted_at: nil) }

  scope :feed_ordered_for, ->(user) {
    return order(id: :desc) unless user

    recommended_for(user)
  }

  scope :recommended_for, lambda { |user|
    latest_own_post_id = where(user_id: user.id).where(deleted_at: nil)
                                .order(id: :desc).limit(1).pluck(:id).first

    from(
      "(SELECT posts.*, " \
      "ROW_NUMBER() OVER (" \
      "  PARTITION BY posts.user_id ORDER BY posts.id DESC" \
      ") AS author_post_rank " \
      "FROM posts WHERE posts.deleted_at IS NULL) AS posts"
    )
    .select(
      "posts.*",
      "CASE WHEN posts.id = '#{latest_own_post_id}' THEN 1 ELSE 0 END AS " \
      "is_top_own",
      "CASE " \
      "  WHEN posts.user_id = '#{user.id}' THEN 10 " \
      "  ELSE COALESCE(user_relationships.score, 0) + " \
      "       COALESCE(reverse_rel.score, 0) * 0.3 " \
      "END AS base_score",
      "CASE " \
      "  WHEN posts.user_id = '#{user.id}' THEN 10.0 / author_post_rank " \
      "  ELSE (COALESCE(user_relationships.score, 0) + " \
      "        COALESCE(reverse_rel.score, 0) * 0.3) / author_post_rank " \
      "END AS diversity_score"
    )
    .joins(
      "LEFT JOIN user_relationships " \
      "ON user_relationships.user_id = '#{user.id}' " \
      "AND user_relationships.target_user_id = posts.user_id"
    )
    .joins(
      "LEFT JOIN user_relationships AS reverse_rel " \
      "ON reverse_rel.target_user_id = '#{user.id}' " \
      "AND reverse_rel.user_id = posts.user_id"
    )
    .order(
      "is_top_own DESC, " \
      "diversity_score DESC, " \
      "posts.id DESC"
    )
  }

  validates :content, presence: true
  validate :prevent_duplicate_recent_post

  def destroy!
    update!(deleted_at: Time.current)
  end

private

  def prevent_duplicate_recent_post
    return if user_id.blank? || content.blank?

    duplicate = Post.visible
      .where(user_id: user_id, content: content)
      .where("created_at > ?", 10.seconds.ago)
      .where.not(id: id)
      .exists?

    if duplicate
      errors.add(:base, "Duplicate post detected")
    end
  end
end
