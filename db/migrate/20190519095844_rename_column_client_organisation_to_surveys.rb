class RenameColumnClientOrganisationToSurveys < ActiveRecord::Migration[5.1]
  def change
    change_table :surveys do |t|
      t.rename :client_organisation, :metas
    end
  end
end
