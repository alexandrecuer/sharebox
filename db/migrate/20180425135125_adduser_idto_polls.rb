class AdduserIdtoPolls < ActiveRecord::Migration[5.1]
  def change
  	add_column :polls, :user_id, :integer
  	add_index :polls, :user_id, :name => "index_polls_on_user_id"
  end
end
