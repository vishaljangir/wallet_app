class WalletTransferService
  class WalletError < StandardError; end
  class InsufficientBalanceError < WalletError; end

  def initialize(from_wallet_id:, to_wallet_id:, amount:, idempotency_key: nil)
    @from_wallet_id = from_wallet_id
    @to_wallet_id   = to_wallet_id
    @amount         = amount
    @idempotency_key = idempotency_key
  end

  def call
    transfer = Transfer.create!(
      from_wallet_id: @from_wallet_id,
      to_wallet_id: @to_wallet_id,
      amount: @amount,
      status: :pending,
      idempotency_key: @idempotency_key
    )

    ActiveRecord::Base.transaction do
      from_wallet = Wallet.lock.find(@from_wallet_id)
      to_wallet   = Wallet.lock.find(@to_wallet_id)

      raise InsufficientBalanceError if from_wallet.balance < @amount

      from_wallet.update!(
        balance: from_wallet.balance - @amount
      )

      to_wallet.update!(
        balance: to_wallet.balance + @amount
      )

      transfer.update!(status: "completed")
    end

    transfer

  rescue WalletError => e
    fail_transfer(transfer, e.message)

  rescue => e
    fail_transfer(transfer, "Unexpected error")
    raise e
  end

  private

    def fail_transfer(transfer, message)
      transfer&.update(
        status: "failed",
        message: message
      )
      transfer
    end
end
