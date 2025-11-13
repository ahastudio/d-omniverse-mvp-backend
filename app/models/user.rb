class User < ApplicationRecord
  include Authenticatable

  validates :id, presence: true, uniqueness: true

  validates :username, presence: true, uniqueness: true

  validates :name, presence: true

  validates :phone_number, presence: true

  validates :nickname, presence: true

  def generate_token
    payload = { sub: id }
    JWT.encode(payload, Rails.application.secret_key_base)
  end
end
