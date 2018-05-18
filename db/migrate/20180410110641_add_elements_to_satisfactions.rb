class AddElementsToSatisfactions < ActiveRecord::Migration[5.1]
  def change
  	add_column :satisfactions, :folder_name, :string

  	add_column :satisfactions, :globale, :string
  	add_column :satisfactions, :ecoute, :string
  	add_column :satisfactions, :disponibilite, :string
  	add_column :satisfactions, :competence, :string
  	add_column :satisfactions, :relationnel, :string
  	add_column :satisfactions, :contrat, :string
  	add_column :satisfactions, :delais, :string
  	add_column :satisfactions, :livrable, :string
  	add_column :satisfactions, :technique, :string
  	add_column :satisfactions, :affaire, :string
  end
end
