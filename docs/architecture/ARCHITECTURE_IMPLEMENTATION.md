# Vertical Slice Architecture Implementation - Rails 8

This project implements Vertical Slice Architecture (VSA) in Ruby on Rails 8, optimized for the ExcelApp AI-powered Excel error correction and automation SaaS platform.

## Ruby on Rails 8 Folder Structure

```
app/
├── features/              # Vertical slices organized by business capability
│   ├── excel_upload/      # File upload functionality
│   │   ├── models/
│   │   │   └── upload_excel_request.rb
│   │   ├── validators/
│   │   │   └── upload_excel_validator.rb
│   │   ├── handlers/
│   │   │   └── upload_excel_handler.rb
│   │   └── responses/
│   │       └── upload_excel_response.rb
│   ├── excel_analysis/    # Excel error analysis
│   │   ├── analyze_errors/
│   │   │   ├── handlers/
│   │   │   │   └── analyze_errors_handler.rb
│   │   │   ├── validators/
│   │   │   │   └── analyze_errors_validator.rb
│   │   │   └── jobs/
│   │   │       └── analyze_errors_job.rb
│   │   └── generate_report/
│   │       └── handlers/
│   │           └── generate_error_report_handler.rb
│   ├── excel_correction/  # Apply corrections to Excel files
│   │   ├── handlers/
│   │   │   └── apply_corrections_handler.rb
│   │   └── jobs/
│   │       └── apply_corrections_job.rb
│   ├── ai_integration/    # AI service integration
│   │   ├── handlers/
│   │   │   └── ai_analysis_handler.rb
│   │   └── services/
│   │       ├── openrouter_service.rb
│   │       └── ai_provider_factory.rb
│   ├── authentication/    # User authentication
│   │   ├── handlers/
│   │   │   ├── login_handler.rb
│   │   │   └── signup_handler.rb
│   │   └── validators/
│   │       ├── login_validator.rb
│   │       └── signup_validator.rb
│   ├── payment/          # Payment processing
│   │   ├── handlers/
│   │   │   └── process_payment_handler.rb
│   │   └── services/
│   │       └── toss_payments_service.rb
│   └── vba_analysis/     # VBA code analysis
│       ├── handlers/
│       │   └── analyze_vba_handler.rb
│       └── services/
│           └── vba_analyzer_service.rb
├── common/               # Shared components (Result pattern, Errors)
│   ├── result.rb        # Result pattern for error handling
│   ├── errors.rb        # Business error definitions
│   └── base_handler.rb  # Base handler with common functionality
├── infrastructure/       # External service implementations
│   ├── external_services/
│   │   ├── file_storage_service.rb
│   │   └── email_service.rb
│   └── adapters/
│       ├── aws_s3_adapter.rb
│       └── redis_adapter.rb
├── controllers/          # API controllers (thin layer)
│   ├── api/
│   │   ├── v1/
│   │   │   ├── files_controller.rb
│   │   │   ├── analysis_controller.rb
│   │   │   ├── auth_controller.rb
│   │   │   └── payments_controller.rb
│   │   └── base_controller.rb
│   └── application_controller.rb
├── models/              # Active Record models
│   ├── user.rb
│   ├── excel_file.rb
│   ├── analysis.rb
│   ├── correction.rb
│   └── payment.rb
├── jobs/                # Background jobs (using Solid Queue)
│   ├── application_job.rb
│   └── concerns/
│       └── trackable.rb
├── services/            # Application services
│   ├── excel/
│   │   ├── analyzer_service.rb
│   │   └── correction_service.rb
│   └── ai/
│       └── base_service.rb
├── components/          # ViewComponent UI components
│   ├── ui/
│   │   ├── button_component.rb
│   │   ├── card_component.rb
│   │   └── dialog_component.rb
│   └── excel/
│       ├── upload_component.rb
│       └── analysis_table_component.rb
├── channels/            # Real-time features (using Solid Cable)
│   ├── application_cable/
│   │   └── connection.rb
│   └── excel_analysis_channel.rb
└── views/               # HTML templates
    ├── layouts/
    │   └── application.html.erb
    └── components/
        └── ui/
            ├── button_component.html.erb
            └── card_component.html.erb
```

## Key Architecture Patterns

### 1. Result Pattern for Error Handling

All business operations return a `Result` object:

```ruby
# app/common/result.rb
class Result
  attr_reader :value, :error, :success

  def initialize(value: nil, error: nil, success: true)
    @value = value
    @error = error
    @success = success
  end

  def self.success(value)
    new(value: value, success: true)
  end

  def self.failure(error)
    new(error: error, success: false)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
```

Usage:
```ruby
result = handler.handle(request)

if result.failure?
  # Handle error
  render json: { error: result.error.message }, status: :bad_request
else
  # Use success value
  render json: { data: result.value }, status: :ok
end
```

### 2. Feature-Based Organization

Each feature is self-contained with its own:
- Request/Response objects
- Validators
- Handlers
- Jobs
- Services

Example:
```ruby
# app/features/excel_upload/handlers/upload_excel_handler.rb
class Features::ExcelUpload::Handlers::UploadExcelHandler < Common::BaseHandler
  def handle(request)
    # Validate request
    validation_result = validate_request(request)
    return validation_result if validation_result.failure?

    # Process file upload
    file_result = process_file_upload(request.file)
    return file_result if file_result.failure?

    # Create database record
    excel_file = ExcelFile.create!(
      user: request.user,
      original_name: request.file.original_filename,
      file_path: file_result.value[:file_path],
      file_size: request.file.size
    )

    # Queue analysis job
    Features::ExcelAnalysis::Jobs::AnalyzeErrorsJob.perform_later(excel_file.id)

    Result.success(
      Features::ExcelUpload::Responses::UploadExcelResponse.new(
        file_id: excel_file.id,
        status: 'uploaded',
        analysis_queued: true
      )
    )
  end

  private

  def validate_request(request)
    validator = Features::ExcelUpload::Validators::UploadExcelValidator.new
    validator.validate(request)
  end

  def process_file_upload(file)
    # File processing logic
    # Returns Result.success(file_path: path) or Result.failure(error)
  end
end
```

### 3. API Controller Integration

Controllers are thin layers that delegate to handlers:

```ruby
# app/controllers/api/v1/files_controller.rb
class Api::V1::FilesController < Api::BaseController
  def create
    request = build_upload_request
    handler = Features::ExcelUpload::Handlers::UploadExcelHandler.new
    result = handler.handle(request)

    if result.failure?
      render json: { error: result.error.message }, status: :bad_request
    else
      render json: { data: result.value }, status: :created
    end
  end

  private

  def build_upload_request
    Features::ExcelUpload::Models::UploadExcelRequest.new(
      file: params[:file],
      user: current_user,
      analysis_options: params[:analysis_options] || {}
    )
  end
end
```

### 4. Business Errors

Defined in `app/common/errors.rb`:

```ruby
# app/common/errors.rb
module Common
  class BusinessError < StandardError
    attr_reader :code, :message, :details

    def initialize(code:, message:, details: {})
      @code = code
      @message = message
      @details = details
      super(message)
    end
  end

  class ExcelErrors
    INVALID_FORMAT = BusinessError.new(
      code: "Excel.InvalidFormat",
      message: "지원하지 않는 Excel 형식입니다"
    )

    EMPTY_FILE = BusinessError.new(
      code: "Excel.EmptyFile",
      message: "빈 파일은 처리할 수 없습니다"
    )

    FILE_TOO_LARGE = BusinessError.new(
      code: "Excel.FileTooLarge",
      message: "파일 크기가 너무 큽니다 (최대 50MB)"
    )

    CORRUPTED_FILE = BusinessError.new(
      code: "Excel.CorruptedFile",
      message: "손상된 파일입니다"
    )
  end

  class AIErrors
    PROVIDER_UNAVAILABLE = BusinessError.new(
      code: "AI.ProviderUnavailable",
      message: "AI 서비스를 이용할 수 없습니다"
    )

    QUOTA_EXCEEDED = BusinessError.new(
      code: "AI.QuotaExceeded",
      message: "AI 사용량 한도를 초과했습니다"
    )

    ANALYSIS_FAILED = BusinessError.new(
      code: "AI.AnalysisFailed",
      message: "AI 분석에 실패했습니다"
    )
  end
end
```

### 5. Background Jobs with Solid Queue

```ruby
# app/features/excel_analysis/jobs/analyze_errors_job.rb
class Features::ExcelAnalysis::Jobs::AnalyzeErrorsJob < ApplicationJob
  queue_as :excel_processing

  def perform(excel_file_id, options = {})
    excel_file = ExcelFile.find(excel_file_id)
    
    # Broadcast progress
    broadcast_progress(excel_file, "분석 시작 중...")

    # Create analysis request
    request = Features::ExcelAnalysis::Models::AnalyzeErrorsRequest.new(
      excel_file: excel_file,
      user: excel_file.user,
      options: options
    )

    # Process with handler
    handler = Features::ExcelAnalysis::Handlers::AnalyzeErrorsHandler.new
    result = handler.handle(request)

    if result.failure?
      broadcast_error(excel_file, result.error.message)
      raise result.error
    end

    broadcast_complete(excel_file, result.value)
  end

  private

  def broadcast_progress(excel_file, message)
    ActionCable.server.broadcast(
      "excel_analysis_#{excel_file.id}",
      {
        status: 'progress',
        message: message,
        timestamp: Time.current
      }
    )
  end

  def broadcast_error(excel_file, error_message)
    ActionCable.server.broadcast(
      "excel_analysis_#{excel_file.id}",
      {
        status: 'error',
        message: error_message,
        timestamp: Time.current
      }
    )
  end

  def broadcast_complete(excel_file, analysis_result)
    ActionCable.server.broadcast(
      "excel_analysis_#{excel_file.id}",
      {
        status: 'complete',
        data: analysis_result,
        timestamp: Time.current
      }
    )
  end
end
```

### 6. Real-time Features with Solid Cable

```ruby
# app/channels/excel_analysis_channel.rb
class ExcelAnalysisChannel < ApplicationCable::Channel
  def subscribed
    file_id = params[:file_id]
    
    # Verify user can access this file
    return reject unless current_user.excel_files.exists?(file_id)
    
    stream_from "excel_analysis_#{file_id}"
  end

  def request_analysis(data)
    file_id = data['file_id']
    options = data['options'] || {}
    
    # Queue analysis job
    Features::ExcelAnalysis::Jobs::AnalyzeErrorsJob.perform_later(file_id, options)
  end
end
```

### 7. Testing Strategy

Focus on integration tests for each feature:

```ruby
# spec/features/excel_upload/upload_excel_spec.rb
RSpec.describe "ExcelUpload Feature", type: :feature do
  let(:user) { create(:user) }
  let(:file) { fixture_file_upload('test_excel.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') }

  describe "uploading a valid Excel file" do
    it "successfully uploads and queues analysis" do
      request = Features::ExcelUpload::Models::UploadExcelRequest.new(
        file: file,
        user: user,
        analysis_options: { auto_correct: true }
      )

      handler = Features::ExcelUpload::Handlers::UploadExcelHandler.new
      result = handler.handle(request)

      expect(result.success?).to be true
      expect(result.value.file_id).to be_present
      expect(result.value.status).to eq('uploaded')
      expect(result.value.analysis_queued).to be true
    end
  end

  describe "uploading an invalid file" do
    let(:invalid_file) { fixture_file_upload('test_document.pdf', 'application/pdf') }

    it "returns validation error" do
      request = Features::ExcelUpload::Models::UploadExcelRequest.new(
        file: invalid_file,
        user: user
      )

      handler = Features::ExcelUpload::Handlers::UploadExcelHandler.new
      result = handler.handle(request)

      expect(result.failure?).to be true
      expect(result.error.code).to eq("Excel.InvalidFormat")
    end
  end
end
```

## Rails 8 Specific Features

### 1. Solid Queue Configuration

```ruby
# config/application.rb
config.solid_queue.connects_to = { database: { writing: :queue } }
config.solid_queue.supervisor = true
config.solid_queue.silence_polling = true
```

### 2. Solid Cable Configuration

```ruby
# config/cable.yml
development:
  adapter: solid_cable
  db_config: cable

production:
  adapter: solid_cable
  db_config: cable
```

### 3. Solid Cache Configuration

```ruby
# config/environments/production.rb
config.cache_store = :solid_cache_store, {
  database: :cache,
  expires_in: 1.hour
}
```

## Migration Guide from Next.js

To migrate existing Next.js code to Rails:

1. **Identify the feature** - What business capability does this code serve?
2. **Create a vertical slice** - New folder under `app/features/`
3. **Extract to handler** - Move logic into a handler class
4. **Add Result pattern** - Return `Result` instead of throwing exceptions
5. **Create API controller** - Thin layer that delegates to handler
6. **Add background jobs** - Use Solid Queue for async processing
7. **Implement real-time features** - Use Solid Cable for WebSocket functionality
8. **Write integration tests** - Focus on testing entire feature slices

## Benefits of This Architecture

1. **Clear boundaries** - Each feature is self-contained
2. **Easy to understand** - All related code in one place
3. **Testable** - Each slice can be tested independently
4. **Scalable** - Add new features without affecting existing ones
5. **Maintainable** - Changes are localized to specific features
6. **Rails 8 optimized** - Leverages Solid Stack for performance
7. **Type safety** - Ruby classes provide structure and validation
8. **Concurrent processing** - Background jobs with Solid Queue
9. **Real-time capabilities** - WebSocket support with Solid Cable

## Database Schema

```ruby
# db/migrate/create_excel_files.rb
class CreateExcelFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :excel_files do |t|
      t.references :user, null: false, foreign_key: true
      t.string :original_name, null: false
      t.string :file_path, null: false
      t.integer :file_size, null: false
      t.string :status, default: 'uploaded'
      t.text :content_hash
      t.timestamps
    end

    add_index :excel_files, :status
    add_index :excel_files, :content_hash
  end
end

# db/migrate/create_analyses.rb
class CreateAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :analyses do |t|
      t.references :excel_file, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :error_count, default: 0
      t.json :ai_analysis
      t.integer :ai_tier_used, default: 1
      t.decimal :confidence_score, precision: 3, scale: 2
      t.string :status, default: 'pending'
      t.integer :tokens_used, default: 0
      t.decimal :cost, precision: 10, scale: 6
      t.timestamps
    end

    add_index :analyses, :status
    add_index :analyses, :ai_tier_used
  end
end
```

## Next Steps

1. **Set up Rails 8 project** with Solid Stack
2. **Implement core features** as vertical slices
3. **Add integration tests** for each feature
4. **Set up CI/CD pipeline** with feature-based testing
5. **Implement UI components** with ViewComponent + shadcn/ui
6. **Add monitoring and logging** for production
7. **Deploy with Kamal** for seamless deployment
8. **Scale horizontally** as needed

This architecture provides a solid foundation for building a maintainable, scalable, and testable Rails application that can handle the complexity of an AI-powered Excel processing platform.