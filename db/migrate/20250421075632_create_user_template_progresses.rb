class CreateUserTemplateProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :template_progresses do |t|
      t.integer :counter, null: false, default: 0
      t.references :template, null: false, foreign_key:  { to_table: :pick_word_in_set_templates }
      t.timestamps
    end
    add_index :dialects_pick_directions, [:dialect_id, :pick_word_in_set_direction_id], name: :index_dialects_pick_directions_on_dialect
    create_table :template_word_progresses do |t|
      t.integer :correct, null: false, default: 0
      t.integer :failed, null: false, default: 0
      t.integer :last_counter, null: false, default: 0
      t.references :word, null: false, foreign_key: true
      t.references :template, null: false, foreign_key:  { to_table: :pick_word_in_set_templates }
      t.timestamps
    end
  end
end
