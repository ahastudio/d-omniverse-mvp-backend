class Post < ApplicationRecord
  include VideoProcessable

  video_attribute :video_url

  belongs_to :user

  scope :visible, -> { where(deleted_at: nil) }

  validates :content, presence: true

  def destroy!
    update!(deleted_at: Time.current)
  end
end
