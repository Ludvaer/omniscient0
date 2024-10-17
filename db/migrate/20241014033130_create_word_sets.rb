class CreateWordSets < ActiveRecord::Migration[7.0]
  def change
    create_table :word_sets do |t|

      t.timestamps
    end
  end
end
