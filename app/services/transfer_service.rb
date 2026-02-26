class TransferService
  class InsufficientBalanceError < StandardError; end
  
  def initialize(from_wallet_id:, to_wallet_id:, amount:, idempotency_key:)
    @from_wallet_id = from_wallet_id
    @to_wallet_id = to_wallet_id
    @amount = amount
    @idempotency_key = idempotency_key
  end

  def call
    ActiveRecord::Base.transaction do
      from_wallet = Wallet.lock.find(@from_wallet_id)
      to_wallet   = Wallet.lock.find(@to_wallet_id)

      raise InsufficientBalanceError, "Insufficient balance in wallet" if from_wallet.balance < @amount

      from_wallet.update!(balance: from_wallet.balance - @amount)
      to_wallet.update!(balance: to_wallet.balance + @amount)

      Transfer.create!(
        from_wallet: from_wallet,
        to_wallet: to_wallet,
        amount: @amount,
        idempotency_key: @idempotency_key,
        status: :completed
      )
    end
  end
end
