class UsersController < ApplicationController
  def create
    user = User.new(user_params)
    user.id = ULID.generate
    user.nickname = user.name
    user.save!

    render json: { accessToken: user.generate_token }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages },
           status: :unprocessable_entity
  end

  private

  def user_params
    params.permit(:username, :password, :name, :phoneNumber)
      .transform_keys(&:underscore)
  end
end
