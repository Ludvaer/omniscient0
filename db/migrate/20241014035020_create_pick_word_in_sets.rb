class CreatePickWordInSets < ActiveRecord::Migration[7.0]
  def change
    create_table :pick_word_in_sets do |t|
      t.integer :correct_id
      t.integer :picked_id
      t.integer :set_id
      t.integer :version

      t.timestamps
    end
  end
end
