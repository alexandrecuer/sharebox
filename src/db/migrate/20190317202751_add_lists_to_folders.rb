class AddListsToFolders < ActiveRecord::Migration[5.1]
  def change
    add_column :folders, :lists, :text
  end

end
