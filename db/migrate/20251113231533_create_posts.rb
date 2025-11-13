class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts, id: false do |t|
      t.string :id, null: false, primary_key: true

      t.string :user_id, null: false, index: true

      t.string :content, null: false

      t.text :video_url

      t.timestamps
    end
  end
end
