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

ActiveRecord::Schema[7.0].define(version: 2023_12_08_184328) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_endpoints", force: :cascade do |t|
    t.bigint "api_slot_id", null: false
    t.string "path"
    t.string "method"
    t.text "commands"
    t.boolean "caching", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_env_vars", force: :cascade do |t|
    t.bigint "api_slot_id", null: false
    t.string "name"
    t.string "value"
    t.string "class_name"
  end

  create_table "api_errors", force: :cascade do |t|
    t.bigint "api_slot_id", null: false
    t.integer "code"
    t.string "message"
  end

  create_table "api_functions", force: :cascade do |t|
    t.bigint "api_slot_id", null: false
    t.string "name"
    t.string "params"
    t.text "commands"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_slots", force: :cascade do |t|
    t.bigint "api_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "documentation"
  end

  create_table "apis", force: :cascade do |t|
    t.bigint "app_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "app_user_snapshots", force: :cascade do |t|
    t.bigint "app_id", null: false
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
    t.bigint "user_id", null: false
    t.bigint "app_id", null: false
    t.bigint "used_storage", default: 0
    t.datetime "last_active", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "apps", force: :cascade do |t|
    t.bigint "dev_id", null: false
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
    t.bigint "table_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "compiled_api_endpoints", force: :cascade do |t|
    t.bigint "api_endpoint_id", null: false
    t.text "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "devs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "api_key"
    t.string "secret_key"
    t.string "uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "app_id", null: false
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
    t.bigint "user_id", null: false
    t.string "stripe_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "user_id", null: false
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
    t.bigint "user_id", null: false
    t.bigint "app_id", null: false
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
    t.bigint "user_id", null: false
    t.bigint "table_id", null: false
    t.string "etag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "table_object_collections", force: :cascade do |t|
    t.bigint "table_object_id", null: false
    t.bigint "collection_id", null: false
    t.datetime "created_at", null: false
  end

  create_table "table_object_prices", force: :cascade do |t|
    t.bigint "table_object_id", null: false
    t.integer "price", default: 0
    t.string "currency", default: "eur"
  end

  create_table "table_object_properties", force: :cascade do |t|
    t.bigint "table_object_id", null: false
    t.string "name"
    t.text "value"
  end

  create_table "table_object_purchases", force: :cascade do |t|
    t.bigint "table_object_id", null: false
    t.bigint "purchase_id", null: false
    t.datetime "created_at", null: false
  end

  create_table "table_object_user_accesses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "table_object_id", null: false
    t.bigint "table_alias"
    t.datetime "created_at", null: false
  end

  create_table "table_objects", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "table_id", null: false
    t.string "uuid"
    t.boolean "file", default: false
    t.string "etag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_table_objects_on_uuid", unique: true
  end

  create_table "table_property_types", force: :cascade do |t|
    t.bigint "table_id", null: false
    t.string "name"
    t.integer "data_type", default: 0
  end

  create_table "tables", force: :cascade do |t|
    t.bigint "app_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "cdn", default: false
  end

  create_table "user_profile_images", force: :cascade do |t|
    t.bigint "user_id", null: false
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
    t.bigint "session_id", null: false
    t.string "uuid"
    t.text "endpoint"
    t.string "p256dh"
    t.string "auth"
    t.datetime "created_at", null: false
    t.index ["uuid"], name: "index_web_push_subscriptions_on_uuid", unique: true
  end

  create_table "websocket_connections", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "app_id", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
  end

  add_foreign_key "api_endpoints", "api_slots", name: "api_endpoints_api_slot_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "api_env_vars", "api_slots", name: "api_env_vars_api_slot_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "api_errors", "api_slots", name: "api_errors_api_slot_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "api_functions", "api_slots", name: "api_functions_api_slot_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "api_slots", "apis", name: "api_slots_api_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "apis", "apps", name: "apis_app_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "app_user_snapshots", "apps", name: "app_user_snapshots_app_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "app_users", "apps", name: "app_users_app_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "app_users", "users", name: "app_users_user_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "apps", "devs", name: "apps_dev_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "collections", "tables", name: "collections_table_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "compiled_api_endpoints", "api_endpoints", name: "compiled_api_endpoints_api_endpoint_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "devs", "users", name: "devs_user_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "notifications", "apps", name: "notifications_app_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "notifications", "users", name: "notifications_user_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "providers", "users", name: "providers_user_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "purchases", "users", name: "purchases_user_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "sessions", "apps", name: "sessions_app_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "sessions", "users", name: "sessions_user_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_etags", "tables", name: "table_etags_table_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_etags", "users", name: "table_etags_user_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_object_collections", "collections", name: "table_object_collections_collection_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_object_collections", "table_objects", name: "table_object_collections_table_object_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_object_prices", "table_objects", name: "table_object_prices_table_object_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_object_properties", "table_objects", name: "table_object_properties_table_object_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_object_purchases", "purchases", name: "table_object_purchases_purchase_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_object_purchases", "table_objects", name: "table_object_purchases_table_object_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_object_user_accesses", "table_objects", name: "table_object_user_accesses_table_object_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_object_user_accesses", "tables", column: "table_alias", name: "table_object_user_accesses_table_alias_fkey", on_update: :cascade, on_delete: :nullify
  add_foreign_key "table_object_user_accesses", "users", name: "table_object_user_accesses_user_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_objects", "tables", name: "table_objects_table_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_objects", "users", name: "table_objects_user_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "table_property_types", "tables", name: "table_property_types_table_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "tables", "apps", name: "tables_app_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "user_profile_images", "users", name: "user_profile_images_user_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "web_push_subscriptions", "sessions", name: "web_push_subscriptions_session_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "websocket_connections", "apps", name: "websocket_connections_app_id_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "websocket_connections", "users", name: "websocket_connections_user_id_fkey", on_update: :cascade, on_delete: :restrict
end
