# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190519095844) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assets", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uploaded_file_file_name"
    t.string "uploaded_file_content_type"
    t.integer "uploaded_file_file_size"
    t.datetime "uploaded_file_updated_at"
    t.integer "folder_id"
    t.index ["folder_id"], name: "index_assets_on_folder_id"
    t.index ["user_id"], name: "index_assets_on_user_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "mel"
    t.string "organisation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "folders", force: :cascade do |t|
    t.string "name"
    t.integer "parent_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "case_number"
    t.integer "poll_id"
    t.text "lists"
    t.index ["parent_id"], name: "index_folders_on_parent_id"
    t.index ["poll_id"], name: "index_folders_on_poll_id"
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "polls", force: :cascade do |t|
    t.string "open_names"
    t.string "closed_names"
    t.string "name"
    t.string "description"
    t.integer "user_id"
    t.integer "closed_names_number"
    t.integer "open_names_number"
    t.index ["user_id"], name: "index_polls_on_user_id"
  end

  create_table "satisfactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "case_number"
    t.integer "folder_id"
    t.integer "poll_id"
    t.integer "closed1"
    t.integer "closed2"
    t.integer "closed3"
    t.integer "closed4"
    t.integer "closed5"
    t.integer "closed6"
    t.integer "closed7"
    t.integer "closed8"
    t.integer "closed9"
    t.integer "closed10"
    t.integer "closed11"
    t.integer "closed12"
    t.integer "closed13"
    t.integer "closed14"
    t.integer "closed15"
    t.integer "closed16"
    t.integer "closed17"
    t.integer "closed18"
    t.integer "closed19"
    t.integer "closed20"
    t.string "open1"
    t.string "open2"
    t.string "open3"
    t.string "open4"
    t.string "open5"
    t.string "open6"
    t.string "open7"
    t.string "open8"
    t.string "open9"
    t.string "open10"
    t.string "open11"
    t.string "open12"
    t.string "open13"
    t.string "open14"
    t.string "open15"
    t.string "open16"
    t.string "open17"
    t.string "open18"
    t.string "open19"
    t.string "open20"
    t.index ["folder_id"], name: "index_satisfactions_on_folder_id"
    t.index ["poll_id"], name: "index_satisfactions_on_poll_id"
    t.index ["user_id"], name: "index_satisfactions_on_user_id"
  end

  create_table "shared_folders", force: :cascade do |t|
    t.integer "user_id"
    t.string "share_email"
    t.integer "share_user_id"
    t.integer "folder_id"
    t.string "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["folder_id"], name: "index_shared_folders_on_folder_id"
    t.index ["share_user_id"], name: "index_shared_folders_on_share_user_id"
    t.index ["user_id"], name: "index_shared_folders_on_user_id"
  end

  create_table "surveys", force: :cascade do |t|
    t.integer "user_id"
    t.integer "poll_id"
    t.string "client_mel"
    t.string "metas"
    t.string "description"
    t.string "by"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "statut", default: "public"
    t.text "groups"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
