# frozen_string_literal: true

module Api
  module V1
    class AiController < Api::V1::BaseController
      before_action :authenticate_user!
      
      def chat
        handler = Ai::Handlers::ChatHandler.new(
          user: current_user,
          message: params[:message],
          conversation_id: params[:conversation_id],
          file_id: params[:file_id]
        )
        
        result = handler.execute
        
        if result.success?
          render json: {
            response: result.value[:response],
            conversation_id: result.value[:conversation_id],
            tokens_used: result.value[:tokens_used],
            ai_tier_used: result.value[:ai_tier_used],
            confidence_score: result.value[:confidence_score]
          }
        else
          render json: {
            error: result.error.message
          }, status: :unprocessable_entity
        end
      end
      
      def feedback
        handler = Ai::Handlers::FeedbackHandler.new(
          user: current_user,
          conversation_id: params[:conversation_id],
          message_id: params[:message_id],
          rating: params[:rating],
          feedback_text: params[:feedback_text]
        )
        
        result = handler.execute
        
        if result.success?
          render json: { message: 'Feedback submitted successfully' }
        else
          render json: {
            error: result.error.message
          }, status: :unprocessable_entity
        end
      end
    end
  end
end