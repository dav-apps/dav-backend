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

ActiveRecord::Schema[7.0].define(version: 2023_12_11_213056) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_endpoints", force: :cascade do |t|
    t.bigint "api_slot_id"
    t.string "path"
    t.string "method"
    t.text "commands"
    t.boolean "caching", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_env_vars", force: :cascade do |t|
    t.bigint "api_slot_id"
    t.string "name"
    t.string "value"
    t.string "class_name"
  end

  create_table "api_errors", force: :cascade do |t|
    t.bigint "api_slot_id"
    t.integer "code"
    t.string "message"
  end

  create_table "api_functions", force: :cascade do |t|
    t.bigint "api_slot_id"
    t.string "name"
    t.string "params"
    t.text "commands"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_slots", force: :cascade do |t|
    t.bigint "api_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "documentation"
  end

  create_table "apis", force: :cascade do |t|
    t.bigint "app_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "app_user_snapshots", force: :cascade do |t|
    t.bigint "app_id"
    t.datetime "time", precision: nil
    t.integer "daily_active", default: 0
    t.integer "monthly_active", default: 0
    t.integer "yearly_active", default: 0
    t.integer "weekly_active", default: 0
    t.integer "free_plan", default: 0
    t.integer "plus_plan", default: 0
    t.integer "pro_plan", default: 0
    t.integer "email_confirmed", default: 0
    t.integer "email_unconfirmed", default: 0
  end

  create_table "app_users", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "app_id"
    t.bigint "used_storage", default: 0
    t.datetime "last_active", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "apps", force: :cascade do |t|
    t.bigint "dev_id"
    t.string "name"
    t.string "description"
    t.boolean "published", default: false
    t.string "web_link"
    t.string "google_play_link"
    t.string "microsoft_store_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "webhook_url"
  end

  create_table "collections", force: :cascade do |t|
    t.bigint "table_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "compiled_api_endpoints", force: :cascade do |t|
    t.bigint "api_endpoint_id"
    t.text "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "devs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "api_key"
    t.string "secret_key"
    t.string "uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "app_id"
    t.string "uuid"
    t.datetime "time", precision: nil
    t.integer "interval"
    t.string "title"
    t.string "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_notifications_on_uuid", unique: true
  end

  create_table "providers", force: :cascade do |t|
    t.bigint "user_id"
    t.string "stripe_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "user_id"
    t.string "payment_intent_id"
    t.string "provider_name"
    t.string "provider_image"
    t.string "product_name"
    t.string "product_image"
    t.integer "price"
    t.string "currency"
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.index ["uuid"], name: "index_purchases_on_uuid", unique: true
  end

  create_table "redis_table_object_operations", force: :cascade do |t|
    t.string "table_object_uuid"
    t.string "operation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "app_id"
    t.string "token"
    t.string "old_token"
    t.string "device_name"
    t.string "device_os"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["old_token"], name: "index_sessions_on_old_token", unique: true
    t.index ["token"], name: "index_sessions_on_token", unique: true
  end

  create_table "table_etags", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "table_id"
    t.string "etag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "table_object_collections", force: :cascade do |t|
    t.bigint "table_object_id"
    t.bigint "collection_id"
    t.datetime "created_at", null: false
  end

  create_table "table_object_prices", force: :cascade do |t|
    t.bigint "table_object_id"
    t.integer "price", default: 0
    t.string "currency", default: "eur"
  end

  create_table "table_object_properties", force: :cascade do |t|
    t.bigint "table_object_id"
    t.string "name"
    t.text "value"
  end

  create_table "table_object_purchases", force: :cascade do |t|
    t.bigint "table_object_id"
    t.bigint "purchase_id"
    t.datetime "created_at", null: false
  end

  create_table "table_object_user_accesses", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "table_object_id"
    t.bigint "table_alias"
    t.datetime "created_at", null: false
  end

  create_table "table_objects", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "table_id"
    t.string "uuid"
    t.boolean "file", default: false
    t.string "etag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_table_objects_on_uuid", unique: true
  end

  create_table "table_property_types", force: :cascade do |t|
    t.bigint "table_id"
    t.string "name"
    t.integer "data_type", default: 0
  end

  create_table "tables", force: :cascade do |t|
    t.bigint "app_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "cdn", default: false
    t.boolean "ignore_file_size", default: false
  end

  create_table "user_profile_images", force: :cascade do |t|
    t.bigint "user_id"
    t.string "ext"
    t.string "mime_type"
    t.string "etag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_snapshots", force: :cascade do |t|
    t.datetime "time", precision: nil
    t.integer "daily_active", default: 0
    t.integer "monthly_active", default: 0
    t.integer "yearly_active", default: 0
    t.integer "weekly_active", default: 0
    t.integer "free_plan", default: 0
    t.integer "plus_plan", default: 0
    t.integer "pro_plan", default: 0
    t.integer "email_confirmed", default: 0
    t.integer "email_unconfirmed", default: 0
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "first_name"
    t.string "password_digest"
    t.boolean "confirmed", default: false
    t.string "email_confirmation_token"
    t.string "password_confirmation_token"
    t.string "old_email"
    t.string "new_email"
    t.string "new_password"
    t.bigint "used_storage", default: 0
    t.datetime "last_active", precision: nil
    t.string "stripe_customer_id"
    t.integer "plan", default: 0
    t.integer "subscription_status", default: 0
    t.datetime "period_end", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "web_push_subscriptions", force: :cascade do |t|
    t.bigint "session_id"
    t.string "uuid"
    t.text "endpoint"
    t.string "p256dh"
    t.string "auth"
    t.datetime "created_at", null: false
    t.index ["uuid"], name: "index_web_push_subscriptions_on_uuid", unique: true
  end

  create_table "websocket_connections", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "app_id"
    t.string "token", null: false
    t.datetime "created_at", null: false
  end

end
