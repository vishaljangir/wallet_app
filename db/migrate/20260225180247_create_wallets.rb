class CreateWallets < ActiveRecord::Migration[8.1]
  def change
    create_table :wallets do |t|
      t.bigint :balance, null: false, default: 0

      t.timestamps
    end
  end
end
