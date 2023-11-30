# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20201022085459) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "auth_level"
    t.string   "first_name"
    t.string   "last_name"
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "app_configs", force: :cascade do |t|
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.integer  "quality_threshold_1",                   default: 4
    t.integer  "quality_threshold_2",                   default: 6
    t.string   "puzzle_sheets_file_name"
    t.string   "puzzle_sheets_content_type"
    t.integer  "puzzle_sheets_file_size",     limit: 8
    t.datetime "puzzle_sheets_updated_at"
    t.string   "sprite_sheet_status",                   default: "fresh"
    t.integer  "image_quality",                         default: 80
    t.text     "twitter_access_token"
    t.text     "twitter_access_token_secret"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "languages", force: :cascade do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pack_puzzles", force: :cascade do |t|
    t.string   "image_id"
    t.text     "puzzle"
    t.text     "extra_data"
    t.integer  "pack_id"
    t.integer  "puzzle_asset_id"
    t.integer  "position"
    t.boolean  "placeholder",            default: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.text     "puzzle_published"
    t.boolean  "data_processing",        default: false
    t.boolean  "status_invalid",         default: false
    t.boolean  "status_missing_locales", default: false
    t.integer  "game_position"
  end

  create_table "packs", force: :cascade do |t|
    t.string   "pack_code"
    t.text     "extra_data"
    t.boolean  "images_processing",                        default: false
    t.datetime "modified_at"
    t.boolean  "published",                                default: false
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.string   "pack_parcel_file_name"
    t.string   "pack_parcel_content_type"
    t.integer  "pack_parcel_file_size"
    t.datetime "pack_parcel_updated_at"
    t.integer  "month"
    t.integer  "year"
    t.boolean  "data_processing",                          default: false
    t.datetime "published_at"
    t.string   "draft_pack_parcel_file_name"
    t.string   "draft_pack_parcel_content_type"
    t.integer  "draft_pack_parcel_file_size",    limit: 8
    t.datetime "draft_pack_parcel_updated_at"
    t.integer  "required_app_version",                     default: 0
    t.boolean  "draft_parcel_processing",                  default: false
    t.boolean  "parcel_processing",                        default: false
    t.string   "status",                                   default: "empty"
    t.string   "worksheet_url"
    t.boolean  "tested_primary",                           default: false
  end

  create_table "puzzle_asset_sheets", force: :cascade do |t|
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size",    limit: 8
    t.datetime "image_updated_at"
    t.string   "pack_type"
    t.integer  "position"
    t.integer  "year"
  end

  create_table "puzzle_assets", force: :cascade do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "image_type"
    t.string   "image_id"
    t.integer  "month"
    t.integer  "year"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "upload_at_size",     default: 50
    t.integer  "pack_id"
    t.boolean  "image_reprocessing", default: false
  end

end
