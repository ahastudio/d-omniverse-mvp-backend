class CreateUserRelationships < ActiveRecord::Migration[8.1]
  def change
    create_table :user_relationships, id: false do |t|
      t.string :id, null: false, primary_key: true

      t.string :user_id, null: false
      t.string :target_user_id, null: false

      t.integer :score, null: false, default: 0

      t.timestamps
    end

    add_index :user_relationships,
              [ :user_id, :target_user_id ],
              unique: true
    add_index :user_relationships, :target_user_id
  end
end
