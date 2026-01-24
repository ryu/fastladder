class AddItemsIndex < ActiveRecord::Migration[4.2]
  def up
    add_index :items, %i[feed_id stored_on created_on id], name: :items_search_index
  end

  def down
    remove_index :items, name: :items_search_index
  end
end
