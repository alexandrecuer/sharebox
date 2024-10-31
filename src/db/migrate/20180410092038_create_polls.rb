class CreatePolls < ActiveRecord::Migration[5.1]
  def change
    create_table :polls do |t|
      t.string :open_names
      t.string :closed_names
      t.string :name
      t.string :description
      t.integer :user_id
      t.integer :closed_names_number
      t.integer :open_names_number
    end

    add_index :polls, :user_id, :name => "index_polls_on_user_id"
  end
end
