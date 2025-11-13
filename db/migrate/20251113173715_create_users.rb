class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: false do |t|
      t.string :id, null: false, primary_key: true

      t.string :username, null: false, index: { unique: true }
      t.string :password_digest, null: false

      t.string :name
      t.string :phone_number

      t.string :nickname
      t.text :bio
      t.string :photo_url

      t.timestamps
    end
  end
end
