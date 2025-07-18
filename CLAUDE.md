# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this Ruby on Rails 8 repository.

## 📋 Project Overview

**ExcelApp Rails** - AI-powered Excel error correction and automation SaaS platform built with Ruby on Rails 8

### Business Goals
- **Primary Goal**: AI 기반 엑셀 오류 자동 감지 및 수정, 최적화 SaaS 플랫폼
- **Scale**: 동시접속 100명 이상 지원 with horizontal scaling capabilities
- **Key Features**: 2단계 AI 시스템, 실시간 처리, 멀티 AI 프로바이더 지원

### Current System Analysis (Next.js Legacy)
The system is being migrated from a fully-implemented Next.js 14 application with:
- ✅ **Complete feature set**: 8 core features fully implemented
- ✅ **Multi-AI integration**: OpenAI, Claude, Gemini, Llama providers
- ✅ **Real-time chat**: WebSocket-based AI chat system
- ✅ **Payment system**: TossPayments integration
- ✅ **Admin dashboard**: Full management interface
- ✅ **Referral system**: Complete referral tracking

## 🏗️ Architecture Principles

This project follows **Vertical Slice Architecture** optimized for Rails 8:

### Core Principles
1. **Feature-First Organization**: Each business function is a self-contained vertical slice
2. **2-Tier AI System**: Cost-efficient AI analysis using Claude 3 Haiku (Tier 1) and Claude 3 Opus (Tier 2)
3. **Rails 8 Solid Stack**: Leverages Solid Queue, Solid Cable, and Solid Cache for performance
4. **Result Pattern**: Business errors use Result<T>, system errors use exceptions
5. **Component-Based UI**: ViewComponent + shadcn/ui for consistent, maintainable UI

### System Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer                            │
│                   (Cloudflare CDN)                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Rails 8 Application                         │
│  ┌─────────────────┬─────────────────┬─────────────────┐    │
│  │   Web Server    │   API Server    │   WebSocket     │    │
│  │    (Puma)       │   (REST API)    │  (Solid Cable) │    │
│  └─────────────────┴─────────────────┴─────────────────┘    │
│                                                             │
│  ┌─────────────────┬─────────────────┬─────────────────┐    │
│  │  Background     │    Caching      │   File System   │    │
│  │ (Solid Queue)   │ (Solid Cache)   │   (AWS S3)      │    │
│  └─────────────────┴─────────────────┴─────────────────┘    │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                  Data Layer                                 │
│  ┌─────────────────┬─────────────────┬─────────────────┐    │
│  │   PostgreSQL    │      Redis      │   External APIs │    │
│  │  (Primary DB)   │   (Cache/Jobs)  │ (AI Providers)  │    │
│  └─────────────────┴─────────────────┴─────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## 📂 Project Structure

```
app/
├── features/                    # All features organized as vertical slices
│   ├── excel_upload/
│   │   ├── handlers/           # Business logic handlers
│   │   ├── validators/         # Request validation
│   │   ├── models/            # Request/Response objects
│   │   ├── jobs/              # Background jobs
│   │   └── services/          # Domain services
│   ├── excel_analysis/
│   │   ├── analyze_errors/
│   │   ├── generate_report/
│   │   └── optimize_formulas/
│   ├── ai_integration/
│   │   ├── multi_provider/
│   │   ├── cost_optimization/
│   │   └── response_validation/
│   ├── payment_processing/
│   ├── user_management/
│   └── admin_dashboard/
├── common/                      # Shared utilities only
│   ├── result.rb               # Result pattern
│   ├── errors.rb               # Business error definitions
│   └── base_handler.rb         # Base handler
├── infrastructure/              # External dependencies
│   ├── ai_providers/
│   ├── file_storage/
│   └── payment_gateways/
├── controllers/                 # Thin API controllers
│   ├── api/v1/
│   └── admin/
├── components/                  # ViewComponent UI components
│   ├── ui/                     # shadcn/ui components
│   └── excel/                  # Domain-specific components
├── services/                    # Application services
├── jobs/                       # Background jobs (Solid Queue)
├── channels/                   # Real-time features (Solid Cable)
└── models/                     # Active Record models
```

## 🛠️ Technology Stack

### Backend Framework
```ruby
# Gemfile - Core Dependencies
gem 'rails', '~> 8.0.0'
gem 'pg', '~> 1.1'                    # PostgreSQL driver
gem 'puma', '~> 6.0'                  # Web server
gem 'redis', '~> 5.0'                 # Redis client
gem 'bootsnap', '>= 1.4.4', require: false

# Rails 8 Solid Stack
gem 'solid_queue'                     # Background jobs
gem 'solid_cable'                     # Real-time WebSocket
gem 'solid_cache'                     # Caching system
gem 'kamal'                          # Deployment tool
gem 'thruster'                       # Static file serving
```

### Excel Processing
```ruby
# Excel processing libraries
gem 'roo', '~> 2.9'                   # Excel file reading
gem 'caxlsx', '~> 3.4'               # Excel file generation
gem 'rubyXL', '~> 3.4'               # Excel file manipulation
gem 'spreadsheet', '~> 1.3'          # Legacy Excel support
gem 'creek', '~> 2.5'                # Large file streaming
```

### AI Integration
```ruby
# AI and HTTP clients
gem 'httparty', '~> 0.21'            # HTTP requests
gem 'faraday', '~> 2.7'              # Advanced HTTP client
gem 'faraday-retry', '~> 2.2'        # Retry middleware
gem 'multi_json', '~> 1.15'          # JSON parsing
gem 'oj', '~> 3.16'                  # Fast JSON processing
```

### Authentication & Security
```ruby
# Authentication (Rails 8 built-in)
gem 'bcrypt', '~> 3.1'               # Password hashing
gem 'jwt', '~> 2.7'                  # JWT tokens
gem 'rack-attack', '~> 6.7'          # Rate limiting
gem 'rack-cors', '~> 2.0'            # CORS configuration
```

### UI Components
```ruby
# Frontend components
gem 'view_component', '~> 3.9'       # Component system
gem 'lookbook', '~> 2.2'             # Component styleguide
gem 'tailwindcss-rails'              # Tailwind CSS
gem 'stimulus-rails'                 # JavaScript framework
gem 'turbo-rails'                    # SPA experience
```

### File Storage & External Services
```ruby
# File storage
gem 'aws-sdk-s3', '~> 1.142'         # AWS S3 integration
gem 'shrine', '~> 3.5'               # File uploads
gem 'mini_magick', '~> 4.12'         # Image processing

# Monitoring
gem 'sentry-ruby'                    # Error tracking
gem 'scout_apm'                      # Performance monitoring
```

## 🎯 Core Features

### 1. Excel File Processing
- **File Upload**: Multi-format support (.xlsx, .xls, .csv)
- **Large File Handling**: Streaming processing for 50MB+ files
- **Error Detection**: Formula errors, data validation, format issues
- **Optimization**: Performance improvements and suggestions

### 2. AI Analysis System
```ruby
# 2-Tier AI System Implementation
class Ai::AnalysisSystem
  TIER1_MODELS = ['claude-3-haiku', 'gpt-3.5-turbo'].freeze
  TIER2_MODELS = ['claude-3-opus', 'gpt-4'].freeze
  
  CONFIDENCE_THRESHOLD = 0.85
  
  def analyze_excel(file_data, user_tier: 1)
    # Tier 1: Cost-efficient analysis
    tier1_result = analyze_with_tier1(file_data)
    
    # Escalate to Tier 2 if confidence < threshold
    if tier1_result.confidence < CONFIDENCE_THRESHOLD
      tier2_result = analyze_with_tier2(file_data, tier1_result)
      return tier2_result
    end
    
    tier1_result
  end
end
```

**AI Provider Configuration**:
- **OpenRouter**: Primary multi-provider access
- **Fallback Chain**: Automatic provider switching
- **Cost Optimization**: Intelligent tier selection
- **Response Caching**: Reduce redundant API calls

### 3. Real-time Features
```ruby
# WebSocket implementation with Solid Cable
class ExcelAnalysisChannel < ApplicationCable::Channel
  def subscribed
    file_id = params[:file_id]
    return reject unless authorized_for_file?(file_id)
    
    stream_from "excel_analysis_#{file_id}"
    transmit(current_analysis_state(file_id))
  end
  
  def receive(data)
    case data['action']
    when 'request_analysis'
      ExcelAnalysisJob.perform_later(data['file_id'], current_user.id)
    end
  end
end
```

### 4. Background Processing
```ruby
# Solid Queue job processing
class ExcelAnalysisJob < ApplicationJob
  queue_as :excel_processing
  
  def perform(file_id, user_id)
    file = ExcelFile.find(file_id)
    user = User.find(user_id)
    
    # Progress tracking
    broadcast_progress(file, "Analysis started...", 0)
    
    # Excel analysis
    analyzer = Excel::AnalyzerService.new(file.file_path)
    errors = analyzer.analyze
    
    broadcast_progress(file, "AI analysis...", 50)
    
    # AI analysis
    ai_service = Ai::MultiProviderService.new
    ai_result = ai_service.analyze_errors(errors, tier: determine_tier(user))
    
    # Save results
    Analysis.create!(
      excel_file: file,
      user: user,
      detected_errors: errors,
      ai_analysis: ai_result.analysis,
      ai_tier_used: ai_result.tier,
      tokens_used: ai_result.tokens_used
    )
    
    broadcast_progress(file, "Complete", 100)
  end
end
```

### 5. Payment System
- **TossPayments Integration**: Korean payment gateway
- **Token-based Billing**: Pay-per-use and subscription models
- **Usage Tracking**: Detailed AI usage and cost monitoring
- **Subscription Management**: Multiple tiers (FREE, BASIC, PRO, ENTERPRISE)

### 6. Admin Dashboard
- **Real-time Analytics**: System health, user activity, revenue
- **User Management**: Role-based access control, usage monitoring
- **AI System Management**: Provider configuration, cost optimization
- **Content Moderation**: Review system, security monitoring

## 🔧 Development Commands

```bash
# Project setup
bundle install
rails db:create db:migrate db:seed

# Development server
bin/dev

# Background jobs
bin/rails solid_queue:start

# Testing
bundle exec rspec
bundle exec rspec --tag focus  # Run focused tests

# Code quality
bundle exec rubocop
bundle exec brakeman           # Security audit

# Database operations
rails db:migrate
rails db:rollback
rails db:reset

# Asset compilation
rails assets:precompile
rails assets:clobber

# Deployment
kamal setup                    # Initial deployment setup
kamal deploy                   # Deploy to production
kamal app logs                 # View application logs
```

## 📋 Development Guidelines

### Code Organization
1. **Vertical Slices**: Create new features as complete vertical slices
2. **Result Pattern**: Use Result<T> for business logic errors
3. **Thin Controllers**: Controllers should only delegate to handlers
4. **Service Layer**: Business logic lives in service objects
5. **Component-Based UI**: Use ViewComponent for all UI components

### AI Integration Guidelines
1. **Cost Management**: Always prefer Tier 1 AI unless complexity requires Tier 2
2. **Prompt Engineering**: Use structured prompts with validation
3. **Response Validation**: Validate AI responses against JSON schema
4. **Caching Strategy**: Cache similar prompts and responses
5. **Error Handling**: Implement fallback chains for AI failures

### Background Jobs
1. **Use Solid Queue**: For all async processing
2. **Progress Tracking**: Always provide user feedback
3. **Error Handling**: Implement retry logic and failure notifications
4. **Resource Management**: Monitor memory usage and processing time

### Testing Strategy
```ruby
# Integration test example
describe 'Excel Analysis Feature' do
  let(:user) { create(:user, tokens: 100) }
  let(:file) { fixture_file_upload('sample.xlsx') }
  
  it 'processes Excel file successfully' do
    post '/api/files', params: { file: file }
    
    expect(response).to have_http_status(:created)
    expect(ExcelAnalysisJob).to have_been_enqueued
  end
end

# Unit test example
describe Excel::AnalyzerService do
  it 'detects formula errors' do
    service = described_class.new('spec/fixtures/error_file.xlsx')
    result = service.analyze
    
    expect(result.errors).to include(
      hash_including(type: 'formula_error')
    )
  end
end
```

## 🎯 Performance Targets

### Response Time Goals
- **Web UI**: < 200ms (95th percentile)
- **API calls**: < 100ms (simple), < 500ms (complex)
- **File upload**: < 5s (50MB files)
- **Excel analysis**: < 30s (50MB files)
- **AI analysis**: < 15s (Tier 1), < 30s (Tier 2)

### Scalability Goals
- **Concurrent users**: 100+ users
- **File processing**: 50 files/minute
- **AI requests**: 200 requests/minute
- **WebSocket connections**: 100 concurrent connections

### Resource Limits
- **Memory usage**: < 2GB per worker
- **CPU usage**: < 80% under normal load
- **Database connections**: 20 connection pool
- **File storage**: 50MB max file size

## 🔒 Security Requirements

### Authentication & Authorization
```ruby
# Role-based access control
class User < ApplicationRecord
  enum role: { user: 0, admin: 1, super_admin: 2 }
  enum tier: { free: 0, basic: 1, pro: 2, enterprise: 3 }
  
  def can_access_admin?
    admin? || super_admin?
  end
  
  def can_use_ai_tier?(tier)
    case tier
    when 1 then tokens >= 5
    when 2 then tokens >= 50 && (pro? || enterprise?)
    else false
    end
  end
end
```

### Data Protection
- **Encryption**: AES-256 for sensitive data
- **File Security**: Encrypted S3 storage
- **Transport Security**: TLS 1.3 for all communications
- **API Security**: JWT tokens with expiration

### Input Validation
```ruby
# Comprehensive input validation
class Excel::UploadValidator
  MAX_FILE_SIZE = 50.megabytes
  ALLOWED_TYPES = %w[.xlsx .xls .csv].freeze
  
  def validate(file)
    errors = []
    
    errors << "File too large" if file.size > MAX_FILE_SIZE
    errors << "Invalid file type" unless valid_type?(file)
    errors << "File corrupted" unless valid_file?(file)
    
    errors.empty? ? Result.success : Result.failure(errors)
  end
end
```

## 📊 Database Schema

### Core Models
```ruby
# User model
class User < ApplicationRecord
  has_secure_password
  
  has_many :excel_files, dependent: :destroy
  has_many :analyses, dependent: :destroy
  has_many :chat_conversations, dependent: :destroy
  has_one :subscription, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true
  validates :tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
end

# Excel file model
class ExcelFile < ApplicationRecord
  belongs_to :user
  has_many :analyses, dependent: :destroy
  
  validates :original_name, presence: true
  validates :file_path, presence: true
  validates :file_size, presence: true
  
  enum status: { uploaded: 0, processing: 1, completed: 2, failed: 3 }
end

# Analysis model
class Analysis < ApplicationRecord
  belongs_to :excel_file
  belongs_to :user
  
  validates :detected_errors, presence: true
  validates :ai_tier_used, presence: true
  validates :tokens_used, presence: true
  
  enum ai_tier_used: { rule_based: 0, tier1: 1, tier2: 2 }
end
```

## 🚀 Deployment

### Development Environment
```bash
# Start development server
bin/dev

# This runs:
# - Rails server (port 3000)
# - Tailwind CSS compiler
# - Solid Queue worker
```

### Production Deployment
```yaml
# config/deploy.yml (Kamal)
service: excelapp
image: excelapp

servers:
  web:
    - 192.168.1.10
    - 192.168.1.11

env:
  clear:
    DATABASE_URL: <%= ENV['DATABASE_URL'] %>
    REDIS_URL: <%= ENV['REDIS_URL'] %>
    OPENROUTER_API_KEY: <%= ENV['OPENROUTER_API_KEY'] %>
    AWS_ACCESS_KEY_ID: <%= ENV['AWS_ACCESS_KEY_ID'] %>
    AWS_SECRET_ACCESS_KEY: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>

accessories:
  db:
    image: postgres:16
    env:
      POSTGRES_DB: excelapp_production
      POSTGRES_USER: excelapp
      POSTGRES_PASSWORD: <%= ENV['POSTGRES_PASSWORD'] %>
  
  redis:
    image: redis:7-alpine
```

### Deployment Commands
```bash
# Initial setup
kamal setup

# Deploy application
kamal deploy

# View logs
kamal app logs

# Rollback
kamal rollback

# Health check
kamal app details
```

## 📈 Monitoring & Logging

### Application Monitoring
```ruby
# Performance monitoring
class MonitoringService
  def self.track_performance(operation, &block)
    start_time = Time.current
    
    result = block.call
    
    Rails.logger.info({
      metric: operation,
      duration: Time.current - start_time,
      status: 'success',
      timestamp: Time.current
    }.to_json)
    
    result
  rescue => e
    Rails.logger.error({
      metric: operation,
      error: e.class.name,
      message: e.message,
      duration: Time.current - start_time,
      timestamp: Time.current
    }.to_json)
    
    raise
  end
end
```

### Health Checks
```ruby
# System health monitoring
class HealthCheckService
  def self.check_system_health
    {
      database: check_database,
      redis: check_redis,
      ai_providers: check_ai_providers,
      file_storage: check_file_storage,
      background_jobs: check_background_jobs
    }
  end
end
```

## 🧪 Testing Guidelines

### Test Structure
```ruby
# RSpec configuration
RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include FactoryBot::Syntax::Methods
  
  # Performance requirements
  config.around(:each, :performance) do |example|
    expect { example.run }.to perform_under(5.seconds)
  end
end

# Test coverage requirement
SimpleCov.start do
  minimum_coverage 90
  add_filter 'spec/'
  add_filter 'vendor/'
end
```

### Integration Testing
```ruby
# Feature testing
describe 'Excel Analysis API' do
  let(:user) { create(:user, tokens: 100) }
  let(:file) { fixture_file_upload('sample.xlsx') }
  
  before { sign_in user }
  
  it 'processes file successfully' do
    post '/api/files', params: { file: file }
    
    expect(response).to have_http_status(:created)
    expect(json_response).to include('file_id')
  end
  
  it 'handles WebSocket updates' do
    file_record = create(:excel_file, user: user)
    
    expect {
      ExcelAnalysisJob.perform_now(file_record.id, user.id)
    }.to have_broadcasted_to("excel_analysis_#{file_record.id}")
  end
end
```

## ❌ Anti-Patterns to Avoid

### Code Organization
- ❌ Fat controllers with business logic
- ❌ Direct AI API calls from controllers
- ❌ Synchronous long-running operations
- ❌ Shared state between features
- ❌ Excessive abstraction without clear benefit

### Performance
- ❌ N+1 queries in database operations
- ❌ Synchronous AI calls without timeout
- ❌ Memory leaks in file processing
- ❌ Blocking operations in main thread

### Security
- ❌ Unvalidated user input
- ❌ Hardcoded credentials
- ❌ Insufficient error handling
- ❌ Missing rate limiting

## 🗺️ Development Roadmap

### Phase 1: Foundation (2 weeks)
- [ ] Rails 8 project setup with Solid Stack
- [ ] Database schema and migrations
- [ ] Authentication system (Rails 8 built-in)
- [ ] Basic file upload functionality

### Phase 2: Core Features (3 weeks)
- [ ] Excel processing engine (roo + caxlsx)
- [ ] AI integration (OpenRouter multi-provider)
- [ ] Background job processing (Solid Queue)
- [ ] Real-time progress tracking (Solid Cable)

### Phase 3: Advanced Features (2 weeks)
- [ ] AI chat interface
- [ ] File optimization features
- [ ] Advanced error correction
- [ ] Performance monitoring

### Phase 4: Business Logic (2 weeks)
- [ ] Payment system (TossPayments)
- [ ] Subscription management
- [ ] Token system and usage tracking
- [ ] Referral system

### Phase 5: Admin & Operations (1 week)
- [ ] Admin dashboard
- [ ] System monitoring
- [ ] User management
- [ ] Analytics and reporting

### Phase 6: Deployment & Testing (1 week)
- [ ] Kamal deployment setup
- [ ] Performance testing
- [ ] Security audit
- [ ] Documentation completion

## 📚 Additional Resources

### Documentation
- [Rails 8 Solid Stack Guide](https://guides.rubyonrails.org/solid_queue.html)
- [ViewComponent Documentation](https://viewcomponent.org/)
- [Kamal Deployment Guide](https://kamal-deploy.org/)

### Best Practices
- Follow Rails conventions and idioms
- Write self-documenting code
- Use descriptive variable and method names
- Implement comprehensive error handling
- Focus on performance and scalability

This comprehensive guide provides all the information needed to develop, deploy, and maintain the ExcelApp Rails application. The system is designed to be scalable, maintainable, and production-ready from day one.