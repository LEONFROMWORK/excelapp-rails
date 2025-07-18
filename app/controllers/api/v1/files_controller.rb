# frozen_string_literal: true

module Api
  module V1
    class FilesController < Api::V1::BaseController
      before_action :authenticate_user!
      before_action :find_file, only: [:show, :destroy, :cancel, :download]

      def index
        files = current_user.excel_files.includes(:analyses)
                           .order(created_at: :desc)
                           .page(params[:page])
                           .per(10)

        render json: {
          files: files.map { |file| serialize_file(file) },
          pagination: {
            current_page: files.current_page,
            total_pages: files.total_pages,
            total_count: files.total_count
          }
        }
      end

      def show
        render json: {
          file: serialize_file_detail(@file)
        }
      end

      def create
        handler = ExcelUpload::Handlers::ProcessUploadHandler.new(
          file: params[:file],
          user: current_user
        )

        result = handler.execute

        if result.success?
          render json: {
            file_id: result.value[:file_id],
            message: result.value[:message]
          }, status: :created
        else
          render json: {
            error: result.error.message,
            code: result.error.code
          }, status: :unprocessable_entity
        end
      end

      def destroy
        if @file.destroy
          render json: { message: 'File deleted successfully' }
        else
          render json: { error: 'Failed to delete file' }, status: :unprocessable_entity
        end
      end

      def cancel
        handler = ExcelAnalysis::Handlers::CancelAnalysisHandler.new(
          excel_file: @file,
          user: current_user
        )

        result = handler.execute

        if result.success?
          render json: {
            success: true,
            message: result.value[:message]
          }
        else
          render json: {
            success: false,
            message: result.error.message
          }, status: :unprocessable_entity
        end
      end

      def download
        if File.exist?(@file.file_path)
          send_file @file.file_path,
                    filename: @file.original_name,
                    type: 'application/octet-stream'
        else
          render json: { error: 'File not found' }, status: :not_found
        end
      end

      private

      def find_file
        @file = current_user.excel_files.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'File not found' }, status: :not_found
      end

      def serialize_file(file)
        {
          id: file.id,
          original_name: file.original_name,
          file_size: file.file_size,
          status: file.status,
          created_at: file.created_at,
          updated_at: file.updated_at,
          analysis_count: file.analyses.count,
          latest_analysis: file.latest_analysis ? serialize_analysis(file.latest_analysis) : nil
        }
      end

      def serialize_file_detail(file)
        {
          id: file.id,
          original_name: file.original_name,
          file_size: file.file_size,
          status: file.status,
          created_at: file.created_at,
          updated_at: file.updated_at,
          analyses: file.analyses.recent.map { |analysis| serialize_analysis(analysis) }
        }
      end

      def serialize_analysis(analysis)
        {
          id: analysis.id,
          ai_tier_used: analysis.ai_tier_used,
          tokens_used: analysis.tokens_used,
          detected_errors: analysis.detected_errors,
          ai_analysis: analysis.ai_analysis,
          created_at: analysis.created_at
        }
      end
    end
  end
end