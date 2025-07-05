class CreateBookmarks < ActiveRecord::Migration[8.0]
  def change
    create_table :bookmarks do |t|
      t.string :url_id, null: false, index: true
      t.string :url, null: false
      t.timestamps
    end
    
    add_index :bookmarks, :url, unique: true
  end
end
