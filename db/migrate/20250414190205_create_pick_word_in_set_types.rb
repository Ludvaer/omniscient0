class CreatePickWordInSetTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :pick_word_in_set_directions do |t|
      t.references :target_dialect, null: false, foreign_key:  { to_table: :dialects }
      t.references :option_dialect, null: false, foreign_key:  { to_table: :dialects }
    end
    create_join_table :dialects, :pick_word_in_set_directions, table_name: :dialects_pick_directions do |t|
      # t.index [:dialect_id, :pick_word_in_set_direction_id]
      t.index [:pick_word_in_set_direction_id, :dialect_id], name: :index_dialects_on_dialects_pick_directions
    end
    create_table :pick_word_in_set_templates do |t|
      t.references :user, null: false, foreign_key: true
      t.references :direction, null: false, foreign_key:  { to_table: :pick_word_in_set_directions }
      t.timestamps
    end
    add_reference :pick_word_in_sets, :template, null: false, foreign_key:  { to_table: :pick_word_in_set_templates }
  end
end
