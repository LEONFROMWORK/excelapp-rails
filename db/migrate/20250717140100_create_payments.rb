class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :payment_intent, null: false, foreign_key: true
      t.integer :amount, null: false
      t.string :payment_method
      t.string :toss_transaction_id, null: false
      t.string :status, null: false, default: 'completed'
      t.json :toss_response_data
      t.datetime :processed_at, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :payments, :toss_transaction_id, unique: true
    add_index :payments, :status
    add_index :payments, :processed_at
  end
end