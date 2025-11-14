class ApplicationController < ActionController::API
  protected

  def login_required
    return if logged_in?

    render json: { error: "Authentication required" },
           status: :unauthorized
  end

  def logged_in?
    current_user.present?
  end

  def current_user
    @current_user ||= find_user_from_token
  end

  def find_user_from_token
    payload = decode_token
    return unless payload

    User.find_by(id: payload["sub"])
  end

  def decode_token
    token = authorization_token
    return unless token

    JWT.decode(
      token,
      Rails.application.secret_key_base,
      true,
      { algorithm: "HS256" }
    ).first
  rescue JWT::DecodeError
    nil
  end

  def authorization_token
    request.headers["Authorization"]&.split(" ")&.last
  end
end
