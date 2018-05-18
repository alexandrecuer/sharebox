class Removehavesatisfactionfromsharedfolders < ActiveRecord::Migration[5.1]
  def change
  	remove_column :shared_folders, :havesatisfaction, :Boolean
  	change_column_default :folders, :havesatisfaction, false
  end
end
