# frozen_string_literal: true

module Api
  module V1
    class PaymentsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_payment_handler

      # POST /api/v1/payments
      def create
        request_model = PaymentProcessing::Models::PaymentRequest.new(payment_params.merge(user: current_user))
        
        unless request_model.valid?
          return render json: {
            success: false,
            errors: request_model.errors.full_messages
          }, status: :unprocessable_entity
        end

        unless request_model.valid_for_user?
          return render json: {
            success: false,
            errors: ['User is not eligible for this payment type']
          }, status: :forbidden
        end

        result = @payment_handler.create_payment(request_model)

        if result.success?
          render json: {
            success: true,
            data: result.value
          }, status: :created
        else
          render json: {
            success: false,
            error: result.error.message
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/payments/confirm
      def confirm
        confirmation_request = PaymentProcessing::Models::PaymentConfirmationRequest.new(confirmation_params)
        
        unless confirmation_request.valid?
          return render json: {
            success: false,
            errors: confirmation_request.errors.full_messages
          }, status: :unprocessable_entity
        end

        result = @payment_handler.confirm_payment(confirmation_request)

        if result.success?
          render json: {
            success: true,
            data: result.value
          }
        else
          render json: {
            success: false,
            error: result.error.message
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/payments
      def index
        handler = UserManagement::Handlers::ListPaymentsHandler.new(
          user: current_user,
          page: params[:page] || 1,
          per_page: params[:per_page] || 10
        )
        
        result = handler.execute
        
        if result.success?
          render json: {
            success: true,
            data: result.value[:payments].map { |payment| serialize_payment(payment) },
            pagination: {
              current_page: result.value[:current_page],
              per_page: result.value[:per_page],
              total_pages: result.value[:total_pages],
              total_count: result.value[:total_count]
            }
          }
        else
          render json: {
            success: false,
            error: result.error.message
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/payments/:id
      def show
        payment = current_user.payments.find(params[:id])
        
        render json: {
          success: true,
          data: serialize_payment(payment)
        }
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Payment not found'
        }, status: :not_found
      end

      # POST /api/v1/payments/webhook
      def webhook
        webhook_request = PaymentProcessing::Models::WebhookRequest.new(
          payload: request.raw_post,
          signature: request.headers['X-Toss-Signature']
        )

        unless webhook_request.valid?
          return head :bad_request
        end

        result = @payment_handler.handle_webhook(webhook_request)

        if result.success?
          head :ok
        else
          Rails.logger.error("Webhook processing failed: #{result.error}")
          head :unprocessable_entity
        end
      end

      private

      def set_payment_handler
        @payment_handler = PaymentProcessing::Handlers::PaymentHandler.new
      end

      def payment_params
        params.require(:payment).permit(:amount, :payment_type, :currency)
      end

      def confirmation_params
        params.permit(:order_id, :payment_key, :amount)
      end

      def serialize_payment(payment)
        {
          id: payment.id,
          amount: payment.amount,
          formatted_amount: payment.formatted_amount,
          payment_method: payment.display_payment_method,
          status: payment.status,
          processed_at: payment.processed_at,
          payment_intent: {
            order_id: payment.payment_intent.order_id,
            payment_type: payment.payment_intent.payment_type,
            display_name: payment.payment_intent.display_name
          },
          can_be_refunded: payment.can_be_refunded?
        }
      end
    end
  end
end