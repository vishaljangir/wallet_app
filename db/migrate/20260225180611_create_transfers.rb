class CreateTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :transfers do |t|
      t.references :from_wallet, null: false, foreign_key: { to_table: :wallets }
      t.references :to_wallet, null: false, foreign_key: { to_table: :wallets }
      t.bigint :amount, null: false
      t.string :idempotency_key, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end
  end
end
