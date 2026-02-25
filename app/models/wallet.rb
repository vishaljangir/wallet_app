class Wallet < ApplicationRecord
    has_many :outgoing_transfers, class_name: 'Transfer', foreign_key: 'from_wallet_id', dependent: :destroy
    has_many :incoming_transfers, class_name: 'Transfer', foreign_key: 'to_wallet_id', dependent: :destroy

    validates :balance, numericality: { greater_than_or_equal_to: 0 }
end
