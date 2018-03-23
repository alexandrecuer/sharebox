class CreateSharedFolders < ActiveRecord::Migration[5.1]
  def change
    create_table :shared_folders do |t|
      t.integer :user_id
      t.string :share_email
      t.integer :share_user_id
      t.integer :folder_id
      t.string :message

      t.timestamps
    end
	
	add_index :shared_folders, :user_id
	add_index :shared_folders, :share_user_id
	add_index :shared_folders, :folder_id
  end
  
end
