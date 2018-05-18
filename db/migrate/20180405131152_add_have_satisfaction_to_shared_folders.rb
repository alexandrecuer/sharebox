class AddHaveSatisfactionToSharedFolders < ActiveRecord::Migration[5.1]
  def change
    add_column :shared_folders, :havesatisfaction, :Boolean
    add_column :folders, :havesatisfaction, :Boolean
  end
end
