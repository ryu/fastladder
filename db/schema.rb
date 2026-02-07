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

ActiveRecord::Schema[8.1].define(version: 2026_02_07_014118) do
  create_table "crawl_statuses", force: :cascade do |t|
    t.datetime "crawled_on", precision: nil
    t.datetime "created_on", precision: nil, null: false
    t.string "digest"
    t.integer "error_count", default: 0, null: false
    t.string "error_message"
    t.integer "feed_id", default: 0, null: false
    t.integer "http_status"
    t.integer "status", default: 1, null: false
    t.integer "update_frequency", default: 0, null: false
    t.datetime "updated_on", precision: nil, null: false
    t.index ["status", "crawled_on"], name: "index_crawl_statuses_on_status_and_crawled_on"
  end

  create_table "favicons", force: :cascade do |t|
    t.integer "feed_id", default: 0, null: false
    t.binary "image"
    t.index ["feed_id"], name: "index_favicons_on_feed_id", unique: true
  end

  create_table "feeds", force: :cascade do |t|
    t.datetime "created_on", precision: nil, null: false
    t.text "description", null: false
    t.string "feedlink", null: false
    t.string "icon"
    t.string "image"
    t.string "link", null: false
    t.datetime "modified_on", precision: nil
    t.integer "subscribers_count", default: 0, null: false
    t.text "title", null: false
    t.datetime "updated_on", precision: nil, null: false
    t.index ["feedlink"], name: "index_feeds_on_feedlink", unique: true
  end

  create_table "folders", force: :cascade do |t|
    t.datetime "created_on", precision: nil, null: false
    t.integer "member_id", default: 0, null: false
    t.string "name", null: false
    t.datetime "updated_on", precision: nil, null: false
    t.index ["member_id", "name"], name: "index_folders_on_member_id_and_name", unique: true
  end

  create_table "items", force: :cascade do |t|
    t.string "author"
    t.text "body", limit: 16777215
    t.string "category"
    t.datetime "created_on", precision: nil, null: false
    t.string "digest"
    t.string "enclosure"
    t.string "enclosure_type"
    t.integer "feed_id", default: 0, null: false
    t.string "guid"
    t.string "link", default: "", null: false
    t.datetime "modified_on", precision: nil
    t.datetime "stored_on", precision: nil
    t.text "title", null: false
    t.datetime "updated_on", precision: nil, null: false
    t.integer "version", default: 1, null: false
    t.index ["digest"], name: "index_items_on_digest"
    t.index ["feed_id", "guid"], name: "index_items_on_feed_id_and_guid", unique: true
    t.index ["feed_id", "stored_on", "created_on", "id"], name: "items_search_index"
  end

  create_table "members", force: :cascade do |t|
    t.string "auth_key"
    t.text "config_dump"
    t.datetime "created_on", precision: nil, null: false
    t.string "crypted_password"
    t.string "email"
    t.boolean "public", default: false, null: false
    t.string "remember_token"
    t.datetime "remember_token_expires_at", precision: nil
    t.string "salt"
    t.datetime "updated_on", precision: nil, null: false
    t.string "username", null: false
    t.index ["auth_key"], name: "index_members_on_auth_key", unique: true
    t.index ["username"], name: "index_members_on_username", unique: true
  end

  create_table "pins", force: :cascade do |t|
    t.datetime "created_on", precision: nil, null: false
    t.string "link", default: "", null: false
    t.integer "member_id", default: 0, null: false
    t.string "title"
    t.datetime "updated_on", precision: nil, null: false
    t.index ["member_id", "link"], name: "index_pins_on_member_id_and_link", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_on", precision: nil, null: false
    t.integer "feed_id", default: 0, null: false
    t.integer "folder_id"
    t.boolean "has_unread", default: false, null: false
    t.boolean "ignore_notify", default: false, null: false
    t.integer "member_id", default: 0, null: false
    t.boolean "public", default: true, null: false
    t.integer "rate", default: 0, null: false
    t.datetime "updated_on", precision: nil, null: false
    t.datetime "viewed_on", precision: nil
    t.index ["feed_id"], name: "index_subscriptions_on_feed_id"
    t.index ["folder_id"], name: "index_subscriptions_on_folder_id"
    t.index ["member_id", "feed_id"], name: "index_subscriptions_on_member_id_and_feed_id", unique: true
  end
end
