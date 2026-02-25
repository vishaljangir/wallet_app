module Api
  module V1
    class TransfersController < ApplicationController

        def create
          begin
            TransferService.new(
              from_wallet_id: transfer_params[:from_wallet_id],
              to_wallet_id: transfer_params[:to_wallet_id],
              amount: transfer_params[:amount],
              idempotency_key: transfer_params[:idempotency_key]
            ).call
            render json: { message: "Success" }
          rescue ActiveRecord::RecordNotFound => e
            render json: { error: e.message }, status: :not_found
          rescue TransferService::SameWalletError => e
            render json: { error: e.message }, status: :unprocessable_entity
          rescue StandardError => e
            render json: { error: e.message }, status: :unprocessable_entity
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
