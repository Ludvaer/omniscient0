class CreateShultes < ActiveRecord::Migration[7.0]
  def change
    create_table :shultes do |t|
      t.integer :user_id
      t.integer :time
      t.integer :mistakes
      t.integer :size
      t.decimal :shuffle

      t.timestamps
    end
  end
end
