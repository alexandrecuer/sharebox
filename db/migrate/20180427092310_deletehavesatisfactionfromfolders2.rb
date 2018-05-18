class Deletehavesatisfactionfromfolders2 < ActiveRecord::Migration[5.1]
  def change
  	remove_column :folders, :havesatisfaction, :boolean
  	add_column :folders, :poll_id, :integer
  	add_index :folders, :poll_id, :name => "index_folders_on_poll_id"
  end
end
