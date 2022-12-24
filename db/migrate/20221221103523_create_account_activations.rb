class CreateAccountActivations < ActiveRecord::Migration[7.0]
  def change
    create_table :account_activations do |t|
      t.integer :user_id
      t.string :token
      t.string :email

      t.timestamps
    end
  end
end
