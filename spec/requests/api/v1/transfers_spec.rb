# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Transfers', type: :request do
  describe 'POST /api/v1/transfers' do
    let!(:from_wallet) { create(:wallet, balance: 1000) }
    let!(:to_wallet)   { create(:wallet, balance: 500) }

    it 'creates a transfer and updates balances' do
      idemp = SecureRandom.uuid

      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 200, idempotency_key: idemp }, as: :json
      expect(response).to have_http_status(:created).or have_http_status(:ok)
      from_wallet.reload
      to_wallet.reload
      expect(from_wallet.balance).to be == 800
      expect(to_wallet.balance).to be == 700
      expect(from_wallet.outgoing_transfers.count).to eq(1)
      transfer = from_wallet.outgoing_transfers.last
      expect(transfer.to_wallet_id).to eq(to_wallet.id)
      expect(transfer.amount).to eq(200)
      expect(transfer.idempotency_key).to eq(idemp)
      expect(transfer.status).to eq('completed')
    end

    it 'rejects transfers with amount less than or equal to 0' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 0, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      from_wallet.reload
      to_wallet.reload
      expect(from_wallet.balance).to be == 1000
      expect(to_wallet.balance).to be == 500
      amount_error = JSON.parse(response.body)['error']
      expect(amount_error).to eq('Unprocessable Content')
      expect(from_wallet.outgoing_transfers.count).to eq(0)
    end

    it 'rejects transfers with insufficient balance' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 1550, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      from_wallet.reload
      to_wallet.reload
      from_wallet.outgoing_transfers.last.tap do |transfer|
        expect(transfer.status).to eq('failed')
        expect(transfer.message).to eq('WalletTransferService::InsufficientBalanceError')
      end
      expect(from_wallet.balance).to be == 1000
      expect(to_wallet.balance).to be == 500
      
      insufficient_balance_error = JSON.parse(response.body)['error']
      expect(insufficient_balance_error).to eq('WalletTransferService::InsufficientBalanceError')
    end

    it 'rejects same-wallet transfers' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: from_wallet.id, amount: 10, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      from_wallet.reload
      to_wallet.reload
      expect(from_wallet.outgoing_transfers.count).to eq(0)
      expect(from_wallet.balance).to be == 1000
      expect(to_wallet.balance).to be == 500
    end

    it 'is idempotent for same (from_wallet_id, idempotency_key)' do
      idemp = SecureRandom.uuid
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 550, idempotency_key: idemp }, as: :json
      first_status = response.status
      from_wallet.reload
      to_wallet.reload
      expect(from_wallet.balance).to be == 450
      expect(to_wallet.balance).to be == 1050

      # second request with same idempotency key should not create a new transfer or change balances
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 3, idempotency_key: idemp }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      from_wallet.reload
      to_wallet.reload
      # balances should have only been changed once
      expect(from_wallet.balance).to be == 450
    end

    it 'returns not found if wallet does not exist' do
      post '/api/v1/transfers', params: { from_wallet_id: 9999, to_wallet_id: to_wallet.id, amount: 10, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns not found if to_wallet does not exist' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: 9999, amount: 10, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unprocessable entity if idempotency key is missing' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 10 }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unprocessable entity if idempotency key is not unique for sender' do
      idemp = SecureRandom.uuid
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 10, idempotency_key: idemp }, as: :json
      expect(response).to have_http_status(:created)

      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 10, idempotency_key: idemp }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unprocessable entity if amount is not a number' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 'abc', idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      from_wallet.reload
      to_wallet.reload
      expect(from_wallet.balance).to be == 1000
      expect(to_wallet.balance).to be == 500
    end

    it 'returns unprocessable entity if amount is negative' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: -50, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      from_wallet.reload
      to_wallet.reload
      expect(from_wallet.balance).to be == 1000
      expect(to_wallet.balance).to be == 500
    end

    it 'returns unprocessable entity if from_wallet_id is missing' do
      post '/api/v1/transfers', params: { to_wallet_id: to_wallet.id, amount: 10, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unprocessable entity if to_wallet_id is missing' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, amount: 10, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unprocessable entity if amount is missing' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
