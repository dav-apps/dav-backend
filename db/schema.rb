# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_11_230926) do

  create_table "app_user_activities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "app_id"
    t.datetime "time"
    t.integer "count_daily", default: 0
    t.integer "count_monthly", default: 0
    t.integer "count_yearly", default: 0
  end

  create_table "app_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "app_id"
    t.bigint "used_storage", default: 0
    t.datetime "last_active"
  end

  create_table "apps", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "dev_id"
    t.string "name"
    t.string "description"
    t.boolean "published", default: false
    t.string "web_link"
    t.string "google_play_link"
    t.string "microsoft_store_link"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "collections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "table_id"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "devs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.string "api_key"
    t.string "secret_key"
    t.string "uuid"
    t.datetime "created_at", precision: 6, null: false
  end

  create_table "exception_events", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "app_id"
    t.string "name"
    t.string "message"
    t.text "stack_trace"
    t.string "app_version"
    t.string "os_version"
    t.string "device_family"
    t.string "locale"
    t.datetime "created_at", precision: 6, null: false
  end

  create_table "providers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.string "stripe_account_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "sessions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "app_id"
    t.string "secret"
    t.datetime "exp"
    t.string "device_name"
    t.string "device_type"
    t.string "device_os"
    t.datetime "created_at", precision: 6, null: false
  end

  create_table "table_object_collections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "table_object_id"
    t.bigint "collection_id"
    t.datetime "created_at", precision: 6, null: false
  end

  create_table "table_object_properties", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "table_object_id"
    t.string "name"
    t.text "value"
  end

  create_table "table_object_user_accesses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "table_object_id"
    t.bigint "table_alias"
    t.datetime "created_at", precision: 6, null: false
  end

  create_table "table_objects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "table_id"
    t.string "uuid"
    t.boolean "file", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["uuid"], name: "index_table_objects_on_uuid", unique: true
  end

  create_table "table_property_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "table_id"
    t.string "name"
    t.integer "data_type", default: 0
  end

  create_table "tables", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "app_id"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "user_activities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "time"
    t.integer "count_daily", default: 0
    t.integer "count_monthly", default: 0
    t.integer "count_yearly", default: 0
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.datetime "last_active"
    t.string "stripe_customer_id"
    t.integer "plan", default: 0
    t.integer "subscription_status", default: 0
    t.timestamp "period_end"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
