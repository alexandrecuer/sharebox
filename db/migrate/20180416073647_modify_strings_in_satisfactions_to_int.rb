class ModifyStringsInSatisfactionsToInt < ActiveRecord::Migration[5.1]
  def change
  	change_column :satisfactions, :globale, :integer, using: 'globale::integer'
  	change_column :satisfactions, :ecoute, :integer, using: 'ecoute::integer'
  	change_column :satisfactions, :disponibilite, :integer, using: 'disponibilite::integer'
  	change_column :satisfactions, :competence, :integer, using: 'competence::integer'
  	change_column :satisfactions, :relationnel, :integer, using: 'relationnel::integer'
  	change_column :satisfactions, :contrat, :integer, using: 'contrat::integer'
  	change_column :satisfactions, :delais, :integer, using: 'delais::integer'
  	change_column :satisfactions, :livrable, :integer, using: 'livrable::integer'
  	change_column :satisfactions, :technique, :integer, using: 'technique::integer'
  	change_column :satisfactions, :affaire, :integer, using: 'affaire::integer'

  end
end
