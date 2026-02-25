class Transfer < ApplicationRecord
  belongs_to :from_wallet, class_name: 'Wallet'
  belongs_to :to_wallet, class_name: 'Wallet'

  validates :amount, numericality: { greater_than: 0 }
  # idempotency_key should be unique per sender (from_wallet)
  validates :idempotency_key, presence: true, uniqueness: { scope: :from_wallet_id }
  validate :different_wallets

  enum :status, { pending: 'pending', completed: 'completed', failed: 'failed' }

  private

  def different_wallets
    if from_wallet_id.present? && to_wallet_id.present? && from_wallet_id == to_wallet_id
      errors.add(:to_wallet_id, 'must be different from from_wallet_id')
    end
  end
end
