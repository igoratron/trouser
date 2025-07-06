class AddContentToBookmarks < ActiveRecord::Migration[8.0]
  def change
    add_column :bookmarks, :content, :json
  end
end
