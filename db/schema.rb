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

ActiveRecord::Schema[8.1].define(version: 2026_03_11_000400) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chore_records", force: :cascade do |t|
    t.jsonb "ai_parse_payload"
    t.bigint "chore_id", null: false
    t.decimal "contribution_points", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "performed_at", null: false
    t.bigint "performed_by_id", null: false
    t.text "source_text"
    t.datetime "updated_at", null: false
    t.index ["chore_id"], name: "index_chore_records_on_chore_id"
    t.index ["created_by_id"], name: "index_chore_records_on_created_by_id"
    t.index ["performed_at"], name: "index_chore_records_on_performed_at"
    t.index ["performed_by_id", "performed_at"], name: "index_chore_records_on_performed_by_id_and_performed_at"
    t.index ["performed_by_id"], name: "index_chore_records_on_performed_by_id"
  end

  create_table "chores", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.decimal "default_contribution_points", precision: 5, scale: 2, default: "1.0", comment: "默认贡献积分"
    t.text "description", comment: "家务描述"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_chores_on_lower_name", unique: true
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_info"
    t.datetime "expires_at", null: false
    t.string "ip"
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_refresh_tokens_on_expires_at"
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name"
    t.string "password_digest", null: false
    t.string "phone", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "chore_records", "chores"
  add_foreign_key "chore_records", "users", column: "created_by_id"
  add_foreign_key "chore_records", "users", column: "performed_by_id"
  add_foreign_key "refresh_tokens", "users"
end
