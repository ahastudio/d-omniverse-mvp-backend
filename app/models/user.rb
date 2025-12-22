class User < ApplicationRecord
  include Authenticatable

  has_many :posts

  before_validation :normalize_username

  validates :id, presence: true, uniqueness: true

  validates :username,
            presence: true,
            uniqueness: true,
            length: { minimum: 3 },
            format: {
              with: /\A[a-z][a-z0-9]*\z/,
              message: "must start with a letter and contain only letters and numbers"
            }

  validates :name, presence: true

  validates :phone_number, presence: true

  validates :nickname, presence: true

  def generate_token
    payload = { sub: id, username: username }
    JWT.encode(payload, Rails.application.secret_key_base)
  end

private

  def normalize_username
    return if username.blank?

    self.username = username.strip.downcase
  end
end
