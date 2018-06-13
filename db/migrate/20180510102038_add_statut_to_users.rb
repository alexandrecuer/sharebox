class AddStatutToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :statut, :string, default: "public"
  end
end
