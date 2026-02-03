class Post < ApplicationRecord
  include VideoProcessable

  video_attribute :video_url

  belongs_to :user

  scope :visible, -> { where(deleted_at: nil) }

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
