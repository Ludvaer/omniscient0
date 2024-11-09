class CreateUserDialectProgresses < ActiveRecord::Migration[7.0]
  def change
    create_table :user_dialect_progresses do |t|
      t.integer :counter

      t.timestamps
    end
    add_reference :user_dialect_progresses, :user, null: false, foreign_key: true
    add_reference :user_dialect_progresses, :dialect, null: false, foreign_key: true
  end
end
