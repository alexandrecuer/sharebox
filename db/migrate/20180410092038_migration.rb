class CreateSatisfactions < ActiveRecord::Migration[5.1]
  def change
    create_table :satisfactions do |t|
      t.timestamps
      t.integer :user_id
      t.string :case_number
      t.integer :folder_id
      t.integer :poll_id
      t.integer :closed1
      t.integer :closed2
      t.integer :closed3
      t.integer :closed4
      t.integer :closed5
      t.integer :closed6
      t.integer :closed7
      t.integer :closed8
      t.integer :closed9
      t.integer :closed10
      t.integer :closed11
      t.integer :closed12
      t.integer :closed13
      t.integer :closed14
      t.integer :closed15
      t.integer :closed16
      t.integer :closed17
      t.integer :closed18
      t.integer :closed19
      t.integer :closed20
      t.string :open1
      t.string :open2
      t.string :open3
      t.string :open4
      t.string :open5
      t.string :open6
      t.string :open7
      t.string :open8
      t.string :open9
      t.string :open10
      t.string :open11
      t.string :open12
      t.string :open13
      t.string :open14
      t.string :open15
      t.string :open16
      t.string :open17
      t.string :open18
      t.string :open19
      t.string :open20
    end

    add_index :satisfactions, :folder_id, :name => "index_satisfactions_on_folder_id"
    add_index :satisfactions, :poll_id, :name => "index_satisfactions_on_poll_id"
    add_index :satisfactions, :user_id, :name => "index_satisfactions_on_user_id"

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

    add_column :folders, :case_number, :string
    add_column :folders, :poll_id, :integer
  	add_index :folders, :poll_id, :name => "index_folders_on_poll_id"

    add_column :users, :statut, :string, default: "public"


  end
end
