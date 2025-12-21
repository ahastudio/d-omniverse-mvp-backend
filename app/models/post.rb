class Post < ApplicationRecord
  include VideoProcessable

  video_attribute :video_url

  belongs_to :user

  validates :content, presence: true
end
