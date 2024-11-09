class ChangeDefaultsInProgresses < ActiveRecord::Migration[7.0]
  def change
    change_column_default :user_translation_learn_progresses, :correct, from: nil, to: 0
    change_column_default :user_translation_learn_progresses, :failed, from: nil, to: 0
    change_column_default :user_translation_learn_progresses, :last_counter, from: nil, to: 0
    change_column_default :user_dialect_progresses, :counter, from: nil, to: 0
  end
end
