module Authenticatable
  extend ActiveSupport::Concern

  included do
    validates :password_digest, presence: true

    attr_reader :password
  end

  def password=(unencrypted_password)
    @password = unencrypted_password

    return if unencrypted_password.blank?

    self.password_digest = Argon2::Password.create(unencrypted_password).to_s
  end

  def authenticate(unencrypted_password)
    return false unless password_digest

    Argon2::Password.verify_password(unencrypted_password, password_digest)
  rescue Argon2::ArgonHashFail
    false
  end
end
