class AddRankToWord < ActiveRecord::Migration[8.0]
  def change
    add_column :words, :rank, :integer, default: 0
  end
end
