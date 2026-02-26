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
    end

    it 'rejects transfers with amount less than or equal to 0' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 0, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      from_wallet.reload
      to_wallet.reload
      expect(from_wallet.balance).to be == 1000
      expect(to_wallet.balance).to be == 500
      amount_error = JSON.parse(response.body)['error']
      expect(amount_error).to eq('Validation failed: Amount must be greater than 0')
    end

    it 'rejects transfers with insufficient balance' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 1550, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      from_wallet.reload
      to_wallet.reload
      expect(from_wallet.balance).to be == 1000
      expect(to_wallet.balance).to be == 500
      insufficient_balance_error = JSON.parse(response.body)['error']
      expect(insufficient_balance_error).to eq('Insufficient balance in wallet')
    end

    it 'rejects same-wallet transfers' do
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: from_wallet.id, amount: 10, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'is idempotent for same (from_wallet_id, idempotency_key)' do
      idemp = SecureRandom.uuid
      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 550, idempotency_key: idemp }, as: :json
      first_status = response.status
      from_wallet.reload
      to_wallet.reload
      expect(from_wallet.balance).to be == 450
      expect(to_wallet.balance).to be == 1050

      post '/api/v1/transfers', params: { from_wallet_id: from_wallet.id, to_wallet_id: to_wallet.id, amount: 3, idempotency_key: idemp }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      from_wallet.reload
      to_wallet.reload
      # balances should have only been changed once
      expect(from_wallet.balance).to be == 450
    end

    it 'returns not found if wallet does not exist' do
      post '/api/v1/transfers', params: { from_wallet_id: 9999, to_wallet_id: to_wallet.id, amount: 10, idempotency_key: SecureRandom.uuid }, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
