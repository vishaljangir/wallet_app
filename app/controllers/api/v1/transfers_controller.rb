module Api
  module V1
    class TransfersController < ApplicationController

        def create
          service = WalletTransferService.new(
            from_wallet_id: transfer_params[:from_wallet_id],
            to_wallet_id: transfer_params[:to_wallet_id],
            amount: transfer_params[:amount],
            idempotency_key: transfer_params[:idempotency_key]
          )

          transfer = service.call

          if transfer.completed?
            render json: transfer, status: :created
          else
            render json: {
              error: transfer.message || "Transfer failed",
              transfer: transfer
            }, status: :unprocessable_entity
          end
        end

        private

          def transfer_params
            allowed = [:from_wallet_id, :to_wallet_id, :amount, :idempotency_key]
            if params[:transfer].present?
              params.require(:transfer).permit(allowed)
            else
              params.permit(allowed)
            end
          end
    end
  end
end
