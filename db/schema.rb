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

ActiveRecord::Schema[7.0].define(version: 2024_11_25_104258) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_activations", force: :cascade do |t|
    t.integer "user_id"
    t.string "token"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "descriptions", force: :cascade do |t|
    t.string "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dialects", force: :cascade do |t|
    t.string "name"
    t.integer "language_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "languages", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "password_resets", force: :cascade do |t|
    t.integer "user_id"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pick_word_in_sets", force: :cascade do |t|
    t.integer "correct_id"
    t.integer "picked_id"
    t.integer "version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "translation_set_id", null: false
    t.bigint "user_id", null: false
    t.bigint "option_dialect_id", default: 7, null: false
    t.index ["option_dialect_id"], name: "index_pick_word_in_sets_on_option_dialect_id"
    t.index ["translation_set_id"], name: "index_pick_word_in_sets_on_translation_set_id"
    t.index ["user_id"], name: "index_pick_word_in_sets_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shultes", force: :cascade do |t|
    t.integer "user_id"
    t.integer "time"
    t.integer "mistakes"
    t.integer "size"
    t.decimal "shuffle"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "translation_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "translation_sets_translations", id: false, force: :cascade do |t|
    t.bigint "translation_id", null: false
    t.bigint "translation_set_id", null: false
  end

  create_table "translations", force: :cascade do |t|
    t.integer "word_id"
    t.string "translation"
    t.integer "translation_dialect_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", default: 0, null: false
    t.integer "priority"
    t.integer "rank"
    t.index ["translation_dialect_id"], name: "index_translations_on_translation_dialect_id"
    t.index ["user_id"], name: "index_translations_on_user_id"
    t.index ["word_id"], name: "index_translations_on_word_id"
  end

  create_table "user_dialect_progresses", force: :cascade do |t|
    t.integer "counter", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "dialect_id", null: false
    t.bigint "source_dialect_id", null: false
    t.index ["dialect_id"], name: "index_user_dialect_progresses_on_dialect_id"
    t.index ["source_dialect_id"], name: "index_user_dialect_progresses_on_source_dialect_id"
    t.index ["user_id"], name: "index_user_dialect_progresses_on_user_id"
  end

  create_table "user_translation_learn_progresses", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "translation_id"
    t.integer "correct", default: 0
    t.integer "failed", default: 0
    t.integer "last_counter", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translation_id"], name: "index_user_translation_learn_progresses_on_translation_id"
    t.index ["user_id"], name: "index_user_translation_learn_progresses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.string "token"
    t.string "downame"
    t.boolean "activated"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "word_in_sets", force: :cascade do |t|
    t.integer "word_set_id"
    t.integer "word_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "word_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "word_sets_words", id: false, force: :cascade do |t|
    t.bigint "word_id", null: false
    t.bigint "word_set_id", null: false
  end

  create_table "words", force: :cascade do |t|
    t.string "spelling"
    t.integer "dialect_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dialect_id"], name: "index_words_on_dialect_id"
    t.index ["spelling"], name: "index_words_on_spelling"
  end

  add_foreign_key "pick_word_in_sets", "dialects", column: "option_dialect_id"
  add_foreign_key "pick_word_in_sets", "translation_sets"
  add_foreign_key "pick_word_in_sets", "users"
  add_foreign_key "translations", "users"
  add_foreign_key "user_dialect_progresses", "dialects"
  add_foreign_key "user_dialect_progresses", "dialects", column: "source_dialect_id"
  add_foreign_key "user_dialect_progresses", "users"
end
