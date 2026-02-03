class UserRelationshipsController < ApplicationController
  before_action :login_required
  before_action :set_target_user, only: [ :create, :show ]
  before_action :set_user_for_index, only: [ :index ]
  before_action :validate_interaction_type, only: [ :create ]

  def index
    relationships = UserRelationship
      .includes(:target_user)
      .where(user_id: @user.id)
      .order(score: :desc)

    render json: {
      relationships: relationships.map do |rel|
        {
          id: rel.target_user.id,
          username: rel.target_user.username,
          nickname: rel.target_user.nickname,
          profileImageUrl: rel.target_user.avatar_url,
          score: rel.score
        }
      end
    }, status: :ok
  end

  def show
    score = UserRelationship.score_for(
      user_id: current_user.id,
      target_user_id: @target_user.id
    )

    render json: { score: score }, status: :ok
  end

  def create
    @relationship = UserRelationship.add_score!(
      user_id: current_user.id,
      target_user_id: @target_user.id,
      interaction_type: interaction_type
    )

    render json: relationship_payload, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages },
           status: :unprocessable_entity
  end

private

  def set_user_for_index
    user_id = params[:userId] || current_user.id
    @user = User.find(user_id)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  def set_target_user
    target_id = params[:targetUserId] || params[:id]
    @target_user = User.find(target_id)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  def validate_interaction_type
    return if UserRelationship::INTERACTION_SCORES.key?(interaction_type)

    render json: { error: "Invalid interaction type" },
           status: :unprocessable_entity
  end

  def interaction_type
    relationship_params[:type]
  end

  def relationship_params
    params.permit(:targetUserId, :type)
      .transform_keys(&:underscore)
  end

  def relationship_payload
    {
      id: @relationship.id,
      userId: @relationship.user_id,
      targetUserId: @relationship.target_user_id,
      score: @relationship.score,
      createdAt: @relationship.created_at&.iso8601,
      updatedAt: @relationship.updated_at&.iso8601
    }
  end
end
