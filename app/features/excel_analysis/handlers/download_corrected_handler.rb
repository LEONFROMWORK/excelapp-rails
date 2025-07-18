# frozen_string_literal: true

module ExcelAnalysis
  module Handlers
    class DownloadCorrectedHandler < Common::BaseHandler
      def initialize(excel_file:, user:)
        @excel_file = excel_file
        @user = user
      end

      def execute
        # Validate preconditions
        validation_result = validate_request
        return validation_result if validation_result.failure?

        # Generate corrected file
        begin
          analysis = @excel_file.latest_analysis
          
          generator = ExcelAnalysis::Services::CorrectedFileGenerator.new(
            excel_file: @excel_file,
            analysis: analysis
          )
          
          result = generator.generate
          
          if result.success?
            Rails.logger.info("Corrected file generated for Excel file #{@excel_file.id}")
            
            Common::Result.success({
              content: result.value[:content],
              filename: "corrected_#{@excel_file.original_name}",
              content_type: determine_content_type,
              excel_file: @excel_file
            })
          else
            Rails.logger.error("Failed to generate corrected file: #{result.error}")
            Common::Result.failure(
              Common::Errors::FileProcessingError.new(
                message: "Failed to generate corrected file",
                file_name: @excel_file.original_name
              )
            )
          end
        rescue StandardError => e
          Rails.logger.error("Error generating corrected file: #{e.message}")
          Common::Result.failure(
            Common::Errors::FileProcessingError.new(
              message: "Error generating corrected file: #{e.message}",
              file_name: @excel_file.original_name
            )
          )
        end
      end

      private

      def validate_request
        errors = []

        # Check if analysis exists and is completed
        analysis = @excel_file.latest_analysis
        unless analysis&.completed?
          errors << "No completed analysis available"
        end

        # Check if corrections are available
        unless analysis&.corrections.present?
          errors << "No corrections available to generate file"
        end

        # Check user owns the file
        unless @excel_file.user == @user
          errors << "You don't have permission to download this file"
        end

        return Common::Result.success if errors.empty?

        Common::Result.failure(
          Common::Errors::ValidationError.new(
            message: "Download validation failed",
            details: { errors: errors }
          )
        )
      end

      def determine_content_type
        extension = File.extname(@excel_file.original_name).downcase
        
        case extension
        when '.xlsx'
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        when '.xls'
          'application/vnd.ms-excel'
        when '.csv'
          'text/csv'
        else
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        end
      end
    end
  end
end