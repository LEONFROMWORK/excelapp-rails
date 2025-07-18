# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::FilesController, type: :controller do
  let(:user) { create(:user, tokens: 100) }
  let(:excel_file) { create(:excel_file, user: user) }
  
  before do
    allow(controller).to receive(:current_user).and_return(user)
  end
  
  describe 'GET #index' do
    let!(:files) { create_list(:excel_file, 3, user: user) }
    
    it 'returns user files' do
      get :index
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['files'].size).to eq(3)
    end
    
    it 'includes pagination' do
      get :index
      
      json = JSON.parse(response.body)
      expect(json).to have_key('pagination')
      expect(json['pagination']).to include('current_page', 'total_pages', 'total_count')
    end
  end
  
  describe 'GET #show' do
    it 'returns file details' do
      get :show, params: { id: excel_file.id }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['file']).to include(
        'id' => excel_file.id,
        'original_name' => excel_file.original_name,
        'status' => excel_file.status
      )
    end
    
    it 'returns 404 for non-existent file' do
      get :show, params: { id: 999 }
      
      expect(response).to have_http_status(:not_found)
    end
    
    it 'returns 404 for other user files' do
      other_user = create(:user)
      other_file = create(:excel_file, user: other_user)
      
      get :show, params: { id: other_file.id }
      
      expect(response).to have_http_status(:not_found)
    end
  end
  
  describe 'POST #create' do
    let(:file) { fixture_file_upload('sample.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') }
    
    before do
      allow(ExcelUpload::Handlers::ProcessUploadHandler).to receive(:new).and_return(mock_handler)
    end
    
    let(:mock_handler) do
      instance_double(ExcelUpload::Handlers::ProcessUploadHandler,
        execute: Common::Result.success(file_id: 123, message: 'File uploaded')
      )
    end
    
    it 'uploads file successfully' do
      post :create, params: { file: file }
      
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json).to include('file_id' => 123, 'message' => 'File uploaded')
    end
    
    it 'handles upload errors' do
      allow(mock_handler).to receive(:execute).and_return(
        Common::Result.failure(
          Common::Errors::ValidationError.new(message: 'Invalid file')
        )
      )
      
      post :create, params: { file: file }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Invalid file')
    end
  end
  
  describe 'DELETE #destroy' do
    it 'deletes file successfully' do
      delete :destroy, params: { id: excel_file.id }
      
      expect(response).to have_http_status(:ok)
      expect(ExcelFile.exists?(excel_file.id)).to be false
    end
    
    it 'returns 404 for non-existent file' do
      delete :destroy, params: { id: 999 }
      
      expect(response).to have_http_status(:not_found)
    end
  end
  
  describe 'POST #cancel' do
    let(:excel_file) { create(:excel_file, user: user, status: 'processing') }
    
    before do
      allow(ExcelAnalysis::Handlers::CancelAnalysisHandler).to receive(:new).and_return(mock_handler)
    end
    
    let(:mock_handler) do
      instance_double(ExcelAnalysis::Handlers::CancelAnalysisHandler,
        execute: Common::Result.success(message: 'Analysis cancelled')
      )
    end
    
    it 'cancels analysis successfully' do
      post :cancel, params: { id: excel_file.id }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include('success' => true, 'message' => 'Analysis cancelled')
    end
    
    it 'handles cancellation errors' do
      allow(mock_handler).to receive(:execute).and_return(
        Common::Result.failure(
          Common::Errors::BusinessError.new(message: 'Cannot cancel')
        )
      )
      
      post :cancel, params: { id: excel_file.id }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json).to include('success' => false, 'message' => 'Cannot cancel')
    end
  end
  
  describe 'GET #download' do
    before do
      allow(File).to receive(:exist?).with(excel_file.file_path).and_return(true)
      allow(controller).to receive(:send_file)
    end
    
    it 'sends file for download' do
      get :download, params: { id: excel_file.id }
      
      expect(controller).to have_received(:send_file).with(
        excel_file.file_path,
        filename: excel_file.original_name,
        type: 'application/octet-stream'
      )
    end
    
    it 'returns 404 when file does not exist' do
      allow(File).to receive(:exist?).with(excel_file.file_path).and_return(false)
      
      get :download, params: { id: excel_file.id }
      
      expect(response).to have_http_status(:not_found)
    end
  end
end