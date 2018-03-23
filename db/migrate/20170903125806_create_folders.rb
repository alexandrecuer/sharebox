class CreateFolders < ActiveRecord::Migration[5.1]
  def change
    create_table :folders do |t|
      t.string :name
      t.integer :parent_id
      t.integer :user_id

      t.timestamps
    end
	
    add_index :folders, :user_id
    add_index :folders, :parent_id
  end
end
