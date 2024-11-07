class AddRankToTranslations < ActiveRecord::Migration[7.0]
  def change
    add_column :translations, :rank, :integer
  end
end
