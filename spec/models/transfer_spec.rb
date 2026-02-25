# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transfer, type: :model do
  it 'is valid with valid attributes' do
    transfer = build(:transfer)
    expect(transfer).to be_valid
  end

  it 'is invalid when amount is not greater than 0' do
    transfer = build(:transfer, amount: 0)
    expect(transfer).not_to be_valid
    expect(transfer.errors[:amount]).to be_present
  end

  it 'does not allow same wallet' do
    wallet = create(:wallet)
    transfer = build(:transfer, from_wallet: wallet, to_wallet: wallet)
    expect(transfer).not_to be_valid
    expect(transfer.errors[:to_wallet_id]).to include('must be different from from_wallet_id')
  end

  it 'requires idempotency key uniqueness scoped to from_wallet' do
    wallet = create(:wallet)
    create(:transfer, from_wallet: wallet, idempotency_key: 'dup-key')
    t = build(:transfer, from_wallet: wallet, idempotency_key: 'dup-key')
    expect(t).not_to be_valid
    expect(t.errors[:idempotency_key]).to be_present
  end
end
