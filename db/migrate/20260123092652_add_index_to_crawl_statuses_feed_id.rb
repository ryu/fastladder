class AddIndexToCrawlStatusesFeedId < ActiveRecord::Migration[8.1]
  def change
    add_index :crawl_statuses, :feed_id, unique: true
  end
end
