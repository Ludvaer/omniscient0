class RemoveSetIdFromPickWordInSet < ActiveRecord::Migration[7.0]
  def change
    remove_column :pick_word_in_sets, :set_id, :integer
  end
end
