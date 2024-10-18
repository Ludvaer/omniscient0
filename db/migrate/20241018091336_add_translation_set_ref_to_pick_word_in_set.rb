class AddTranslationSetRefToPickWordInSet < ActiveRecord::Migration[7.0]
  def change
    add_reference :pick_word_in_sets, :translation_set, null: false, foreign_key: true
  end
end
