class User < ApplicationRecord
  include Authenticatable

  validates :id, presence: true, uniqueness: true

  validates :username, presence: true, uniqueness: true

  validates :name, presence: true

  validates :phone_number, presence: true

  validates :nickname, presence: true
end
