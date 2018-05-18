class ModifySatisfactionsFields < ActiveRecord::Migration[5.1]
  def change
  	rename_column :satisfactions, :globale, :closed1
  	rename_column :satisfactions, :ecoute, :closed2
  	rename_column :satisfactions, :disponibilite, :closed3
  	rename_column :satisfactions, :competence, :closed4
  	rename_column :satisfactions, :relationnel, :closed5
  	rename_column :satisfactions, :contrat, :closed6
  	rename_column :satisfactions, :delais, :closed7
  	rename_column :satisfactions, :livrable, :closed8
  	rename_column :satisfactions, :technique, :closed9
  	rename_column :satisfactions, :affaire, :closed10

  	rename_column :satisfactions, :commentaire, :open1
  	rename_column :satisfactions, :attente, :open2

  	add_column :satisfactions, :user_id, :integer
  	add_column :satisfactions, :title, :string
  	add_column :satisfactions, :case_number, :string
  end
end
