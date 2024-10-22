class AddTranslationRelatedIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :words, :spelling
    add_index :words, :dialect_id
    add_index :translations, :word_id
    add_index :translations, :translation_dialect_id
  end
end
