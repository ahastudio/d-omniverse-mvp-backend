class User < ApplicationRecord
  include Authenticatable

  validates :id, presence: true, uniqueness: true

  validates :username, presence: true, uniqueness: true

  validates :name, presence: true

  validates :phone_number,
            format: { with: /\A\d{3}-\d{4}-\d{4}\z/, allow_blank: true }

  validates :nickname, presence: true
end
