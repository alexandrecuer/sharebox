class AddGroupsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :groups, :text
  end
end
