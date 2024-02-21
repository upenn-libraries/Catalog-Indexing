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

ActiveRecord::Schema[7.1].define(version: 2024_02_21_213443) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "alma_exports", force: :cascade do |t|
    t.string "target_collections", default: [], array: true
    t.string "status"
    t.string "alma_source"
    t.boolean "full", default: true, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "webhook_body"
  end

  create_table "batch_files", force: :cascade do |t|
    t.bigint "alma_export_id"
    t.string "path"
    t.string "status"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string "error_messages", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alma_export_id"], name: "index_batch_files_on_alma_export_id"
  end

  create_table "config_items", force: :cascade do |t|
    t.string "name"
    t.jsonb "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "batch_files", "alma_exports"
end
