class CreateJoinTableWordWordSet < ActiveRecord::Migration[7.0]
  def change
    create_join_table :words, :word_sets do |t|
      # t.index [:word_id, :word_set_id]
      # t.index [:word_set_id, :word_id]
    end
  end
end
