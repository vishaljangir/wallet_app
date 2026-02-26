# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transfer, type: :model do
  it 'is valid with valid attributes' do
    transfer = build(:transfer)
    expect(transfer).to be_valid
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

  it 'allows same idempotency key for different from_wallet' do
    wallet1 = create(:wallet)
    wallet2 = create(:wallet)
    create(:transfer, from_wallet: wallet1, idempotency_key: 'dup-key')
    t = build(:transfer, from_wallet: wallet2, idempotency_key: 'dup-key')
    expect(t).to be_valid
  end

  it 'has enum status' do
    transfer = build(:transfer)
    expect(transfer).to respond_to(:pending?)
    expect(transfer).to respond_to(:completed?)
    expect(transfer).to respond_to(:failed?)
  end

  it 'is pending by default' do
    transfer = build(:transfer)
    expect(transfer.status).to eq('pending')
  end

  it 'belongs to from_wallet and to_wallet' do
    transfer = build(:transfer)
    expect(transfer).to respond_to(:from_wallet)
    expect(transfer).to respond_to(:to_wallet)
  end

  it 'validates presence of from_wallet and to_wallet' do
    transfer = build(:transfer, from_wallet: nil)
    expect(transfer).not_to be_valid
    expect(transfer.errors[:from_wallet]).to be_present

    transfer = build(:transfer, to_wallet: nil)
    expect(transfer).not_to be_valid
    expect(transfer.errors[:to_wallet]).to be_present
  end

  it 'validates numericality of amount' do
    transfer = build(:transfer, amount: 'not-a-number')
    expect(transfer).not_to be_valid
    expect(transfer.errors[:amount]).to be_present
  end

  it 'validates that amount is greater than 0' do
    transfer = build(:transfer, amount: -10)
    expect(transfer).not_to be_valid
    expect(transfer.errors[:amount]).to be_present
  end

  it 'validates that from_wallet and to_wallet are different' do
    wallet = create(:wallet)
    transfer = build(:transfer, from_wallet: wallet, to_wallet: wallet)
    expect(transfer).not_to be_valid
    expect(transfer.errors[:to_wallet_id]).to include('must be different from from_wallet_id')
  end
end
