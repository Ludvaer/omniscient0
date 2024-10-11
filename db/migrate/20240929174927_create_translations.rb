class CreateTranslations < ActiveRecord::Migration[7.0]
  def change
    create_table :translations do |t|
      t.integer :word_id
      t.string :translation
      t.integer :translation_dialect_id

      t.timestamps
    end
  end
end
