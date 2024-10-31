class CreateClients < ActiveRecord::Migration[5.1]
  def change
    create_table :clients do |t|
      t.string :mel
      t.string :organisation

      t.timestamps
    end
  end
end
