# frozen_string_literal: true

FactoryBot.define do
  factory :transfer do
    association :from_wallet, factory: :wallet
    association :to_wallet, factory: :wallet
    amount { 100 }
    idempotency_key { SecureRandom.uuid }
    status { :pending }
  end
end
