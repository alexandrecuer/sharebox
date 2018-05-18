class ChangeBooleanHaveSatisfactionToString < ActiveRecord::Migration[5.1]
  def change
  	change_column :folders, :havesatisfaction, :string
  end
end
