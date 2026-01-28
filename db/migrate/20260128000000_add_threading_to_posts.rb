class AddThreadingToPosts < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:posts, :parent_id)
      add_column :posts, :parent_id, :string
    end

    unless column_exists?(:posts, :replies_count)
      add_column :posts, :replies_count, :integer, default: 0, null: false
    end

    unless column_exists?(:posts, :deleted_at)
      add_column :posts, :deleted_at, :datetime
    end

    unless index_exists?(:posts, :parent_id)
      add_index :posts, :parent_id
    end

    unless index_exists?(:posts, :deleted_at)
      add_index :posts, :deleted_at
    end
  end
end
