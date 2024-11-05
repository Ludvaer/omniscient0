class CreateUserTranslationLearnProgresses < ActiveRecord::Migration[7.0]
  def change
    create_table :user_translation_learn_progresses do |t|
      t.bigint :user_id
      t.bigint :translation_id
      t.integer :correct
      t.integer :failed
      t.integer :last_counter

      t.timestamps
    end
    add_index :user_translation_learn_progresses, :user_id
    add_index :user_translation_learn_progresses, :translation_id
  end
end
