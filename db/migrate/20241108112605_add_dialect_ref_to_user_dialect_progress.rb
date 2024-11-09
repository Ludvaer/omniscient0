class AddDialectRefToUserDialectProgress < ActiveRecord::Migration[7.0]
  def change
    add_reference :user_dialect_progresses, :source_dialect, null: false, foreign_key: { to_table: :dialects }
  end
end
