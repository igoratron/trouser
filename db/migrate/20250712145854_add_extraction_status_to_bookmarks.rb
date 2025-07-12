class AddExtractionStatusToBookmarks < ActiveRecord::Migration[8.0]
  def change
    add_column :bookmarks, :extraction_status, :integer, default: 0, null: false
    add_index :bookmarks, :extraction_status
  end
end
