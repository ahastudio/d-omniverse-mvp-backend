class UserRelationship < ApplicationRecord
  INTERACTION_SCORES = {
    "profile_view" => 1,
    "reaction" => 2,
    "post_view" => 1
  }.freeze

  belongs_to :user
  belongs_to :target_user, class_name: "User"

  validates :user_id, presence: true
  validates :target_user_id, presence: true
  validates :score, presence: true, numericality: { only_integer: true }
  validates :user_id, uniqueness: { scope: :target_user_id }

  validate :cannot_target_self

  def self.add_score!(user_id:, target_user_id:, interaction_type:)
    score_value = INTERACTION_SCORES[interaction_type]
    return nil unless score_value

    relationship = find_or_initialize_by(
      user_id: user_id,
      target_user_id: target_user_id
    )
    relationship.id ||= ULID.generate
    relationship.score += score_value
    relationship.save!
    relationship
  end

  def self.score_for(user_id:, target_user_id:)
    find_by(user_id: user_id, target_user_id: target_user_id)&.score || 0
  end

private

  def cannot_target_self
    return unless user_id == target_user_id

    errors.add(:target_user_id, "cannot be the same as user")
  end
end
