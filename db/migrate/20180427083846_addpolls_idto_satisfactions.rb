class AddpollsIdtoSatisfactions < ActiveRecord::Migration[5.1]
  def change
  	add_column :satisfactions, :poll_id, :integer
  	add_index :satisfactions, :poll_id, :name => "index_satisfactions_on_poll_id"
  end
end
