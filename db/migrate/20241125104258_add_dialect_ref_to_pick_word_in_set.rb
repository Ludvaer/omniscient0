class AddDialectRefToPickWordInSet < ActiveRecord::Migration[7.0]
  def change
    add_reference :pick_word_in_sets, :option_dialect, null: false, foreign_key:  { to_table: :dialects }, default: 7
  end
end
