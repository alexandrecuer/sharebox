# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2019_07_27_173609) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "assets", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "uploaded_file_file_name"
    t.string "uploaded_file_content_type"
    t.bigint "uploaded_file_file_size"
    t.datetime "uploaded_file_updated_at", precision: nil
    t.integer "folder_id"
    t.index ["folder_id"], name: "index_assets_on_folder_id"
    t.index ["user_id"], name: "index_assets_on_user_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "mel"
    t.string "organisation"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "folders", force: :cascade do |t|
    t.string "name"
    t.integer "parent_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "statut", default: "public"
    t.text "groups"
    t.string "lang"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
end
