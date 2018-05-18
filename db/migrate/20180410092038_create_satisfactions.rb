class CreateSatisfactions < ActiveRecord::Migration[5.1]
  def change
    create_table :satisfactions do |t|
      t.string :commentaire
      t.string :attente

      t.timestamps
    end
  end
end
