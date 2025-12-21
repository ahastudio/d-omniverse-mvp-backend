class UsersController < ApplicationController
  before_action :login_required, only: [ :update ]
  before_action :set_user, only: [ :show, :update ]

  def show
    render json: user_payload(@user),
           status: :ok
  end

  def create
    user = User.new(create_user_params)
    user.id = ULID.generate
    user.nickname = user.name
    user.save!

    render json: { accessToken: user.generate_token }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages },
           status: :unprocessable_entity
  end

  def update
    @user.update!(update_params)

    render json: user_payload(@user),
           status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages },
           status: :unprocessable_entity
  end

private

  def set_user
    @user = User.find_by!(username: params[:username])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" },
           status: :not_found
  end

  def user_payload(user)
    {
      id: user.id,
      username: user.username,
      nickname: user.nickname,
      bio: user.bio || "",
      avatarUrl: user.avatar_url
    }
  end

  def create_user_params
    params.permit(:username, :password, :name, :phoneNumber)
      .transform_keys(&:underscore)
  end

  def update_params
    params.permit(:nickname, :bio, :avatarUrl)
      .transform_keys(&:underscore)
  end
end
