class AddGuidToItems < ActiveRecord::Migration[4.2]
  def up
    add_column :items, :guid, :string
    remove_index :items, %i[feed_id link]

    # Use raw SQL to avoid dependency on Item model
    # This ensures the migration works even if the model changes
    execute <<~SQL.squish
      UPDATE items SET guid = link WHERE guid IS NULL
    SQL

    add_index :items, %i[feed_id guid], unique: true
  end

  def down
    remove_index :items, %i[feed_id guid]
    add_index :items, %i[feed_id link], unique: true
    remove_column :items, :guid
  end
end
