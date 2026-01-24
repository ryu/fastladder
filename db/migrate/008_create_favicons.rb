class CreateFavicons < ActiveRecord::Migration[4.2]
  def up
    create_table :favicons do |t|
      t.integer :feed_id, default: 0, null: false
      t.binary :image
    end
    add_index :favicons, :feed_id, unique: true
  end

  def down
    drop_table :favicons
  end
end
