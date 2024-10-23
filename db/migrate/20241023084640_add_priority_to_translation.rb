class AddPriorityToTranslation < ActiveRecord::Migration[7.0]
  def change
    add_column :translations, :priority, :integer
  end
end
