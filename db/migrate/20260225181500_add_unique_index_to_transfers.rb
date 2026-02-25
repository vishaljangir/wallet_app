class AddUniqueIndexToTransfers < ActiveRecord::Migration[8.1]
  def change
    add_index :transfers, [:from_wallet_id, :idempotency_key], unique: true, name: 'index_transfers_on_from_wallet_and_idempotency'
  end
end
