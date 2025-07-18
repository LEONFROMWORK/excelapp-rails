# frozen_string_literal: true

class ExcelFilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_excel_file, only: [:show, :analyze, :download_corrected]

  def index
    @excel_files = current_user.excel_files.includes(:analyses).recent.page(params[:page])
  end

  def show
    @latest_analysis = @excel_file.latest_analysis
  end

  def new
    @excel_file = current_user.excel_files.build
  end

  def create
    handler = ExcelUpload::Handlers::UploadExcelHandler.new(
      user: current_user,
      file: params[:file]
    )
    
    result = handler.call
    
    if result.success?
      redirect_to excel_file_path(result.value.file_id), 
                  notice: "File uploaded successfully and queued for processing"
    else
      flash.now[:alert] = result.error.is_a?(Array) ? result.error.join(", ") : result.error.message
      render :new, status: :unprocessable_entity
    end
  end

  def analyze
    handler = ExcelAnalysis::Handlers::AnalyzeExcelHandler.new(
      excel_file: @excel_file,
      user: current_user
    )
    
    result = handler.execute
    
    if result.success?
      redirect_to @excel_file, notice: result.value[:message]
    else
      error_message = result.error.is_a?(Common::Errors::ValidationError) ? 
                     result.error.details[:errors].join(", ") : 
                     result.error.message
      redirect_to @excel_file, alert: error_message
    end
  end

  def download_corrected
    handler = ExcelAnalysis::Handlers::DownloadCorrectedHandler.new(
      excel_file: @excel_file,
      user: current_user
    )
    
    result = handler.execute
    
    if result.success?
      send_data result.value[:content],
                filename: result.value[:filename],
                type: result.value[:content_type]
    else
      error_message = result.error.is_a?(Common::Errors::ValidationError) ? 
                     result.error.details[:errors].join(", ") : 
                     result.error.message
      redirect_to @excel_file, alert: error_message
    end
  end

  private

  def set_excel_file
    @excel_file = current_user.excel_files.find(params[:id])
  end
end