module Authenticatable
  extend ActiveSupport::Concern

  class AuthenticationFailed < StandardError; end

  included do
    validates :password_digest, presence: true

    attr_reader :password
  end

  def password=(unencrypted_password)
    @password = unencrypted_password

    if unencrypted_password.blank?
      self.password_digest = nil
      return
    end

    self.password_digest = hash_password(unencrypted_password)
  end

  def authenticate(unencrypted_password)
    return false if unencrypted_password.blank?

    password_digest && verify_password(unencrypted_password)
  end

  def authenticate!(unencrypted_password)
    raise AuthenticationFailed unless authenticate(unencrypted_password)
  end

  private

  def hash_password(unencrypted_password)
    Argon2::Password.create(unencrypted_password).to_s
  end

  def verify_password(unencrypted_password)
    Argon2::Password.verify_password(
      unencrypted_password,
      password_digest
    )
  rescue Argon2::ArgonHashFail
    false
  end
end
