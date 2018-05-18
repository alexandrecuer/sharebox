class AddFolderIdToSatisfactions < ActiveRecord::Migration[5.1]
  def change
  	remove_column :satisfactions, :folder_name, :string
  	add_column :satisfactions, :folder_id, :integer
  	add_index :satisfactions, :folder_id, :name => "index_satisfactions_on_folder_id"
  	add_index :satisfactions, :user_id, :name => "index_satisfactions_on_user_id"
  end
end
