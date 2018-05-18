class AddFieldsToPolls < ActiveRecord::Migration[5.1]
  def change
  	add_column :polls, :closed_names_number, :integer
  	add_column :polls, :open_names_number, :integer
  end
end
