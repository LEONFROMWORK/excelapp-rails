# frozen_string_literal: true

module Ai
  module Handlers
    class ChatHandler < Common::BaseHandler
      def initialize(user:, message:, conversation_id: nil, file_id: nil)
        @user = user
        @message = message
        @conversation_id = conversation_id
        @file_id = file_id
      end

      def execute
        return failure("Message cannot be blank") if @message.blank?
        return failure("Insufficient tokens") unless @user.tokens >= minimum_tokens_required

        conversation = find_or_create_conversation
        file_context = @file_id ? ExcelFile.find_by(id: @file_id, user: @user) : nil

        # 2-tier AI system
        tier1_response = process_with_tier1
        
        if tier1_response[:confidence_score] >= 0.85
          finalize_response(conversation, tier1_response, 1)
        else
          tier2_response = process_with_tier2(tier1_response)
          finalize_response(conversation, tier2_response, 2)
        end
      end

      private

      attr_reader :user, :message, :conversation_id, :file_id

      def find_or_create_conversation
        if @conversation_id
          @user.chat_conversations.find(@conversation_id)
        else
          @user.chat_conversations.create!(
            title: @message.truncate(50),
            excel_file_id: @file_id
          )
        end
      end

      def minimum_tokens_required
        5 # Tier 1 requires 5 tokens minimum
      end

      def process_with_tier1
        service = Ai::MultiProviderService.new(tier: 1)
        context = build_context
        
        response = service.chat(
          message: @message,
          context: context,
          user: @user
        )
        
        {
          response: response[:message],
          confidence_score: response[:confidence_score] || 0.7,
          tokens_used: response[:tokens_used] || 5,
          provider: response[:provider]
        }
      end

      def process_with_tier2(tier1_response)
        return failure("Insufficient tokens for Tier 2 analysis") unless @user.can_use_ai_tier?(2)
        
        service = Ai::MultiProviderService.new(tier: 2)
        context = build_context
        
        response = service.chat(
          message: @message,
          context: context,
          previous_response: tier1_response[:response],
          user: @user
        )
        
        {
          response: response[:message],
          confidence_score: response[:confidence_score] || 0.9,
          tokens_used: (tier1_response[:tokens_used] || 5) + (response[:tokens_used] || 50),
          provider: response[:provider]
        }
      end

      def build_context
        context = {
          user_tier: @user.tier,
          conversation_history: recent_messages
        }
        
        if @file_id && file = @user.excel_files.find_by(id: @file_id)
          context[:file_info] = {
            name: file.original_name,
            size: file.file_size,
            status: file.status,
            analyses: file.analyses.recent.limit(3).map { |a|
              {
                detected_errors: a.detected_errors,
                ai_analysis: a.ai_analysis,
                created_at: a.created_at
              }
            }
          }
        end
        
        context
      end

      def recent_messages
        return [] unless @conversation_id
        
        conversation = @user.chat_conversations.find(@conversation_id)
        conversation.chat_messages.recent.limit(10).map { |msg|
          {
            role: msg.role,
            content: msg.content,
            created_at: msg.created_at
          }
        }
      end

      def finalize_response(conversation, ai_response, tier_used)
        # Save user message
        user_message = conversation.chat_messages.create!(
          role: 'user',
          content: @message
        )
        
        # Save AI response
        ai_message = conversation.chat_messages.create!(
          role: 'assistant',
          content: ai_response[:response],
          ai_tier_used: tier_used,
          tokens_used: ai_response[:tokens_used],
          confidence_score: ai_response[:confidence_score],
          provider: ai_response[:provider]
        )
        
        # Consume tokens
        @user.consume_tokens!(ai_response[:tokens_used])
        
        success({
          response: ai_response[:response],
          conversation_id: conversation.id,
          tokens_used: ai_response[:tokens_used],
          ai_tier_used: tier_used,
          confidence_score: ai_response[:confidence_score]
        })
      rescue => e
        failure("Failed to process AI response: #{e.message}")
      end
    end
  end
end