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

ActiveRecord::Schema[7.1].define(version: 2026_03_22_003759) do
  create_table "goal_nodes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title"
    t.string "node_type"
    t.integer "estimate"
    t.boolean "completed"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_goal_nodes_on_user_id"
  end

  create_table "moko_items", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "item_id"
    t.string "rarity"
    t.datetime "unlocked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_moko_items_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer "duration"
    t.integer "points"
    t.string "quality"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "device_id"
    t.integer "level"
    t.integer "xp"
    t.integer "streak"
    t.integer "coins"
    t.integer "rest_days"
    t.datetime "last_sync_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_users_on_device_id"
  end

  add_foreign_key "goal_nodes", "users"
  add_foreign_key "moko_items", "users"
  add_foreign_key "sessions", "users"
end
