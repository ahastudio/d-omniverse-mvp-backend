class UserRelationshipsController < ApplicationController
  before_action :login_required
  before_action :set_target_user, only: [ :create, :show ]
  before_action :validate_interaction_type, only: [ :create ]

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
