class CreateWordInSets < ActiveRecord::Migration[7.0]
  def change
    create_table :word_in_sets do |t|
      t.integer :word_set_id
      t.integer :word_id

      t.timestamps
    end
  end
end
