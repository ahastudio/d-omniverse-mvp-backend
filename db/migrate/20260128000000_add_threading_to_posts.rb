class AddThreadingToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :parent_id, :string
    add_column :posts, :replies_count, :integer, default: 0, null: false

    add_column :posts, :deleted_at, :datetime

    add_index :posts, :parent_id
    add_index :posts, :deleted_at
  end
end
