class CreatePolls < ActiveRecord::Migration[5.1]
  def change
    create_table :polls do |t|
    	t.string :open_names
    	t.string :closed_names
    	t.string :name
    	t.string :description
    end
  end
end
