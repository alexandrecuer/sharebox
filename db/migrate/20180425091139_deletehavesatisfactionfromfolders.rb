class Deletehavesatisfactionfromfolders < ActiveRecord::Migration[5.1]
  def change
  	remove_column :folders, :havesatisfaction, :string
  	add_column :folders, :havesatisfaction, :boolean, :default => false
  end
end
