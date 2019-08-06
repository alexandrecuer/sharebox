class AddLangToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :lang, :string
  end
end
