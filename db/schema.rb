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

ActiveRecord::Schema[8.1].define(version: 2026_02_26_165013) do
  create_table "transfers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "amount", null: false
    t.datetime "created_at", null: false
    t.bigint "from_wallet_id", null: false
    t.string "idempotency_key", null: false
    t.string "message"
    t.string "status", default: "pending", null: false
    t.bigint "to_wallet_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_wallet_id", "idempotency_key"], name: "index_transfers_on_from_wallet_and_idempotency", unique: true
    t.index ["from_wallet_id"], name: "index_transfers_on_from_wallet_id"
    t.index ["to_wallet_id"], name: "index_transfers_on_to_wallet_id"
  end

  create_table "wallets", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "balance", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "transfers", "wallets", column: "from_wallet_id"
  add_foreign_key "transfers", "wallets", column: "to_wallet_id"
end
