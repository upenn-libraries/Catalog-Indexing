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

ActiveRecord::Schema[7.0].define(version: 2023_08_25_184448) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "batch_files", force: :cascade do |t|
    t.bigint "publish_job_id"
    t.string "path"
    t.string "status"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "error_messages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publish_job_id"], name: "index_batch_files_on_publish_job_id"
  end

  create_table "publish_jobs", force: :cascade do |t|
    t.string "target_collections", array: true
    t.string "status"
    t.string "alma_source"
    t.string "initiated_by"
    t.boolean "full", default: true, null: false
    t.text "webhook_body"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "batch_files", "publish_jobs"
end
