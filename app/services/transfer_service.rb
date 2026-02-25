class TransferService
  class SameWalletError < StandardError; end
  
  def initialize(from_wallet_id:, to_wallet_id:, amount:, idempotency_key:)
    @from_wallet_id = from_wallet_id
    @to_wallet_id = to_wallet_id
    @amount = amount
    @idempotency_key = idempotency_key
  end

  def call
    amount_in_cents = convert_to_cents(@amount)

    ActiveRecord::Base.transaction do
      from_wallet = Wallet.lock.find(@from_wallet_id)
      to_wallet   = Wallet.lock.find(@to_wallet_id)

      raise "Insufficient balance" if from_wallet.balance < amount_in_cents

      from_wallet.update!(balance: from_wallet.balance - amount_in_cents)
      to_wallet.update!(balance: to_wallet.balance + amount_in_cents)

      Transfer.create!(
        from_wallet: from_wallet,
        to_wallet: to_wallet,
        amount: amount_in_cents,
        idempotency_key: @idempotency_key,
        status: :completed
      )
    end
  end

  private

    def convert_to_cents(amount)
      (amount.to_d * 100).to_i
    end
end
