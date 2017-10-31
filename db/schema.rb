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

ActiveRecord::Schema.define(version: 20171030231208) do

  create_table "players", force: :cascade do |t|
    t.string "name"
    t.string "position"
    t.string "team"
    t.string "injury_status"
    t.string "bye_week"
    t.string "ffn_id"
    t.string "yahoo_id"
    t.integer "team_id"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "yahoo_key"
    t.string "rotoworld_key"
    t.integer "rotoworld_id"
    t.string "lookup_key"
    t.float "points", default: 0.0
  end

  create_table "projections", force: :cascade do |t|
    t.integer "player_id"
    t.integer "week"
    t.float "standard"
    t.float "standard_low"
    t.float "standard_high"
    t.float "ppr"
    t.float "ppr_low"
    t.float "ppr_high"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "yahoo_id"
    t.string "yahoo_key"
    t.integer "yahoo_owner_id"
    t.string "yahoo_owner_name"
    t.string "name"
  end

  create_table "yahoo_ffs", force: :cascade do |t|
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
