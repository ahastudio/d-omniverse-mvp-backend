class AddDepthToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :depth, :integer, null: false, default: 0
  end
end
