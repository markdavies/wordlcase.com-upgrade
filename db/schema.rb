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

ActiveRecord::Schema[7.1].define(version: 2023_12_06_113139) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "auth_level"
    t.string "first_name"
    t.string "last_name"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "app_configs", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "quality_threshold_1", default: 4
    t.integer "quality_threshold_2", default: 6
    t.string "puzzle_sheets_file_name"
    t.string "puzzle_sheets_content_type"
    t.bigint "puzzle_sheets_file_size"
    t.datetime "puzzle_sheets_updated_at", precision: nil
    t.string "sprite_sheet_status", default: "fresh"
    t.integer "image_quality", default: 80
    t.text "twitter_access_token"
    t.text "twitter_access_token_secret"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "languages", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "pack_puzzles", id: :serial, force: :cascade do |t|
    t.string "image_id"
    t.text "puzzle"
    t.text "extra_data"
    t.integer "pack_id"
    t.integer "puzzle_asset_id"
    t.integer "position"
    t.boolean "placeholder", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "puzzle_published"
    t.boolean "data_processing", default: false
    t.boolean "status_invalid", default: false
    t.boolean "status_missing_locales", default: false
    t.integer "game_position"
  end

  create_table "packs", id: :serial, force: :cascade do |t|
    t.string "pack_code"
    t.text "extra_data"
    t.boolean "images_processing", default: false
    t.datetime "modified_at", precision: nil
    t.boolean "published", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "pack_parcel_file_name"
    t.string "pack_parcel_content_type"
    t.integer "pack_parcel_file_size"
    t.datetime "pack_parcel_updated_at", precision: nil
    t.integer "month"
    t.integer "year"
    t.boolean "data_processing", default: false
    t.datetime "published_at", precision: nil
    t.string "draft_pack_parcel_file_name"
    t.string "draft_pack_parcel_content_type"
    t.bigint "draft_pack_parcel_file_size"
    t.datetime "draft_pack_parcel_updated_at", precision: nil
    t.integer "required_app_version", default: 0
    t.boolean "draft_parcel_processing", default: false
    t.boolean "parcel_processing", default: false
    t.string "status", default: "empty"
    t.string "worksheet_url"
    t.boolean "tested_primary", default: false
  end

  create_table "puzzle_asset_sheets", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "image_file_name"
    t.string "image_content_type"
    t.bigint "image_file_size"
    t.datetime "image_updated_at", precision: nil
    t.string "pack_type"
    t.integer "position"
    t.integer "year"
  end

  create_table "puzzle_assets", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "image_type"
    t.string "image_id"
    t.integer "month"
    t.integer "year"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "image_file_name"
    t.string "image_content_type"
    t.integer "image_file_size"
    t.datetime "image_updated_at", precision: nil
    t.integer "upload_at_size", default: 50
    t.integer "pack_id"
    t.boolean "image_reprocessing", default: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
