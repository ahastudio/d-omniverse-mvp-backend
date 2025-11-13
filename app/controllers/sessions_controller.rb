class SessionsController < ApplicationController
  before_action :set_user, only: [:create]
  before_action :verify_password, only: [:create]

  def create
    render json: { id: @user.id, username: @user.username },
           status: :created
  end

  private

  def session_params
    params.permit(:username, :password)
      .transform_keys(&:underscore)
  end

  def set_user
    @user = User.find_by!(username: session_params[:username])
  rescue ActiveRecord::RecordNotFound
    render_unauthorized
  end

  def verify_password
    @user.authenticate!(session_params[:password])
  rescue Authenticatable::AuthenticationFailed
    render_unauthorized
  end

  def render_unauthorized
    render json: { error: "Invalid username or password" },
           status: :unauthorized
  end
end
