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

  class << self
    def add_score!(user_id:, target_user_id:, interaction_type:)
      score = INTERACTION_SCORES[interaction_type]
      return nil unless score

      ensure_not_self!(user_id:, target_user_id:)
      upsert_relationship(user_id:, target_user_id:, score:)
    end

    def score_for(user_id:, target_user_id:)
      find_by(user_id: user_id, target_user_id: target_user_id)&.score || 0
    end

  private

    def ensure_not_self!(user_id:, target_user_id:)
      return unless user_id == target_user_id

      raise ActiveRecord::RecordInvalid, self_target_error_record(user_id)
    end

    def self_target_error_record(user_id)
      new(user_id: user_id, target_user_id: user_id, score: 0).tap do |r|
        r.errors.add(:target_user_id, "cannot be the same as user")
      end
    end

    def upsert_relationship(user_id:, target_user_id:, score:)
      sql = build_upsert_sql(user_id:, target_user_id:, score:)
      instantiate(connection.exec_query(sql).first)
    end

    def build_upsert_sql(user_id:, target_user_id:, score:)
      t = Time.current
      sanitize_sql_array(
        [UPSERT_SQL, ULID.generate, user_id, target_user_id, score, t, t, score, t]
      )
    end

    UPSERT_SQL = <<~SQL.squish.freeze
      INSERT INTO user_relationships
        (id, user_id, target_user_id, score, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT (user_id, target_user_id) DO UPDATE
      SET score = user_relationships.score + ?, updated_at = ?
      RETURNING *
    SQL
  end

private

  def cannot_target_self
    return unless user_id == target_user_id

    errors.add(:target_user_id, "cannot be the same as user")
  end
end
