# frozen_string_literal: true

module ExcelAnalysis
  module Handlers
    class AnalyzeExcelHandler < Common::BaseHandler
      def initialize(excel_file:, user:, tier: nil)
        @excel_file = excel_file
        @user = user
        @tier = tier || determine_optimal_tier
      end

      def execute
        return failure("File not found") unless @excel_file
        return failure("File not ready for analysis") unless @excel_file.can_be_analyzed?
        return failure("Insufficient tokens") unless @user.can_use_ai_tier?(@tier)

        # Update file status to processing
        @excel_file.update!(status: 'processing')

        # Broadcast progress update
        broadcast_progress("Starting Excel analysis...", 10)

        begin
          # Step 1: Extract and analyze file structure
          file_data = extract_file_data
          broadcast_progress("File structure analyzed", 25)

          # Step 2: Detect errors using rule-based system
          detected_errors = detect_errors(file_data)
          broadcast_progress("Errors detected: #{detected_errors.count}", 50)

          # Step 3: AI analysis
          ai_analysis = perform_ai_analysis(file_data, detected_errors)
          broadcast_progress("AI analysis completed", 75)

          # Step 4: Save results
          analysis = save_analysis_results(detected_errors, ai_analysis)
          broadcast_progress("Analysis saved", 90)

          # Step 5: Update file status
          @excel_file.update!(status: 'analyzed')
          broadcast_progress("Analysis complete", 100)

          success({
            message: "Analysis completed successfully",
            analysis_id: analysis.id,
            errors_found: detected_errors.count,
            ai_tier_used: ai_analysis[:tier_used],
            tokens_used: ai_analysis[:tokens_used]
          })
        rescue => e
          @excel_file.update!(status: 'failed')
          broadcast_progress("Analysis failed: #{e.message}", 0)
          failure("Analysis failed: #{e.message}")
        end
      end

      private

      attr_reader :excel_file, :user, :tier

      def determine_optimal_tier
        # Use tier 1 for basic users, tier 2 for pro+ users with complex files
        if @user.pro? || @user.enterprise?
          @excel_file.file_size > 10.megabytes ? 2 : 1
        else
          1
        end
      end

      def extract_file_data
        analyzer = Excel::FileAnalyzer.new(@excel_file.file_path)
        analyzer.extract_data
      end

      def detect_errors(file_data)
        detector = Excel::ErrorDetector.new(file_data)
        detector.detect_all_errors
      end

      def perform_ai_analysis(file_data, errors)
        # Start with tier 1 analysis
        tier1_service = AiIntegration::Services::MultiProviderService.new(tier: 1)
        tier1_result = tier1_service.analyze_excel(
          file_data: {
            name: @excel_file.original_name,
            size: @excel_file.file_size
          },
          user: @user,
          errors: errors
        )

        # Check if we need tier 2 analysis
        if tier1_result[:confidence_score] < 0.85 && @user.can_use_ai_tier?(2)
          broadcast_progress("Escalating to advanced AI analysis...", 60)
          
          tier2_service = AiIntegration::Services::MultiProviderService.new(tier: 2)
          tier2_result = tier2_service.analyze_excel(
            file_data: {
              name: @excel_file.original_name,
              size: @excel_file.file_size
            },
            user: @user,
            errors: errors
          )

          # Consume tokens for both tiers
          total_tokens = tier1_result[:tokens_used] + tier2_result[:tokens_used]
          @user.consume_tokens!(total_tokens)

          {
            analysis: tier2_result[:message],
            structured_analysis: tier2_result[:structured_analysis],
            tier_used: 2,
            confidence_score: tier2_result[:confidence_score],
            tokens_used: total_tokens,
            provider: tier2_result[:provider]
          }
        else
          # Use tier 1 result
          @user.consume_tokens!(tier1_result[:tokens_used])

          {
            analysis: tier1_result[:message],
            structured_analysis: tier1_result[:structured_analysis],
            tier_used: 1,
            confidence_score: tier1_result[:confidence_score],
            tokens_used: tier1_result[:tokens_used],
            provider: tier1_result[:provider]
          }
        end
      end

      def save_analysis_results(errors, ai_analysis)
        Analysis.create!(
          excel_file: @excel_file,
          user: @user,
          detected_errors: errors,
          ai_analysis: ai_analysis[:analysis],
          structured_analysis: ai_analysis[:structured_analysis],
          ai_tier_used: ai_analysis[:tier_used],
          confidence_score: ai_analysis[:confidence_score],
          tokens_used: ai_analysis[:tokens_used],
          provider: ai_analysis[:provider],
          status: 'completed'
        )
      end

      def broadcast_progress(message, percentage)
        ActionCable.server.broadcast(
          "excel_analysis_#{@excel_file.id}",
          {
            type: 'progress_update',
            message: message,
            percentage: percentage,
            file_id: @excel_file.id,
            timestamp: Time.current.iso8601
          }
        )
      end
    end
  end
end