class CreateSurveys < ActiveRecord::Migration[5.1]
  def change
    create_table :surveys do |t|
      t.integer :user_id
      t.integer :poll_id
      t.string :client_mel
      t.string :client_organisation
      t.string :description
      t.string :by
      t.string :token

      t.timestamps
    end
  end
end
