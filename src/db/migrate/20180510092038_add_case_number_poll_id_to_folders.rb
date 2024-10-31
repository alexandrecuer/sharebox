class AddCaseNumberPollIdToFolders < ActiveRecord::Migration[5.1]
  def change
    add_column :folders, :case_number, :string
    add_column :folders, :poll_id, :integer
  	add_index :folders, :poll_id, :name => "index_folders_on_poll_id"
  end
end
