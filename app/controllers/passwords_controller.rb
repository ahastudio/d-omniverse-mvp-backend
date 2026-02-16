class PasswordsController < ApplicationController
  before_action :login_required
  before_action :set_user
  before_action :verify_owner

  def update
    password_params = params.permit(:oldPassword, :newPassword)
                            .transform_keys(&:underscore)

    unless @user.authenticate(password_params[:old_password])
      render json: { error: "Invalid current password" },
             status: :unprocessable_entity
      return
    end

    @user.password = password_params[:new_password]
    @user.save!

    head :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages },
           status: :unprocessable_entity
  end

private

  def set_user
    username = params[:user_username].to_s.downcase
    @user = User.find_by(username: username)

    return if @user

    render json: { error: "User not found" }, status: :not_found
  end

  def verify_owner
    return unless @user
    return if @user == current_user

    render json: { error: "Forbidden" }, status: :forbidden
  end
end
