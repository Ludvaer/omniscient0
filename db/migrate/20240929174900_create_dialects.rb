class CreateDialects < ActiveRecord::Migration[7.0]
  def change
    create_table :dialects do |t|
      t.string :name
      t.integer :language_id

      t.timestamps
    end
  end
end
