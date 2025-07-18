# Dashboard UI Integration

이 문서는 ExcelApp Rails와 Dashboard UI 간의 통합 방법을 설명합니다.

## 개요

ExcelApp Rails는 이제 BigData Dashboard UI와 완전히 통합되어 다음 기능을 제공합니다:

- **데이터 수집 파이프라인 관리**: StackOverflow, Reddit, Oppadu 데이터 수집 제어
- **AI 비용 모니터링**: 실시간 AI 사용량 추적 및 예산 관리
- **실시간 대시보드**: 시스템 상태 모니터링 및 로그 조회

## 새로 추가된 API 엔드포인트

### 1. 대시보드 통합 API (`/api/v1/dashboard`)

```ruby
# 파이프라인 상태 조회
GET /api/v1/dashboard/status

# 파이프라인 시작
POST /api/v1/dashboard/run-pipeline
POST /api/v1/dashboard/run-continuous

# 파이프라인 정지
POST /api/v1/dashboard/stop-pipeline

# 시스템 로그 조회
GET /api/v1/dashboard/logs

# 데이터셋 목록 조회
GET /api/v1/dashboard/datasets

# 캐시 정리
POST /api/v1/dashboard/cache/cleanup

# 수집 데이터 저장
POST /api/v1/dashboard/collection/save
```

### 2. AI 비용 모니터링 API (`/api/v1/ai_cost_monitoring`)

```ruby
# 계정 잔액 조회
GET /api/v1/ai_cost_monitoring/balance

# 사용량 통계 조회
GET /api/v1/ai_cost_monitoring/usage?days=7

# 사용 가능한 모델 목록
GET /api/v1/ai_cost_monitoring/models
```

### 3. 설정 관리 API (`/api/v1/settings`)

```ruby
# 현재 AI 모델 조회
GET /api/v1/settings/model

# AI 모델 변경
POST /api/v1/settings/model

# OpenRouter 설정 조회
GET /api/v1/settings/openrouter

# OpenRouter 설정 업데이트
POST /api/v1/settings/openrouter
```

## 데이터베이스 변경사항

### 새로운 테이블: `ai_usage_records`

AI 사용량 추적을 위한 테이블이 추가되었습니다:

```ruby
create_table :ai_usage_records do |t|
  t.references :user, null: true, foreign_key: true
  t.string :model_id, null: false
  t.integer :provider, null: false, default: 0
  t.decimal :cost, precision: 10, scale: 6, null: false, default: 0.0
  t.integer :input_tokens, null: false, default: 0
  t.integer :output_tokens, null: false, default: 0
  t.integer :request_type, null: false, default: 0
  t.text :request_prompt, null: true
  t.text :response_content, null: true
  t.json :metadata, null: true
  t.decimal :latency_ms, precision: 10, scale: 2, null: true
  t.string :request_id, null: true
  t.string :session_id, null: true
  
  t.timestamps
end
```

## 사용 방법

### 1. 마이그레이션 실행

```bash
cd /Users/kevin/excelapp-rails
rails db:migrate
```

### 2. 환경 변수 설정

```bash
# .env 파일에 추가
OPENROUTER_API_KEY=your_openrouter_api_key
AI_MONTHLY_LIMIT=25.0
BIGDATA_SYSTEM_PATH=/Users/kevin/bigdata/new_system
```

### 3. Dashboard UI 설정

Dashboard UI에서 API 베이스 URL을 ExcelApp Rails 서버로 설정:

```javascript
// dashboard-ui/lib/api.ts
const API_BASE_URL = 'http://localhost:3000/api/v1';
```

### 4. 서버 시작

```bash
# ExcelApp Rails 서버 시작
cd /Users/kevin/excelapp-rails
rails server

# Dashboard UI 서버 시작 (다른 터미널)
cd /Users/kevin/bigdata/dashboard-ui
npm run dev
```

## 주요 기능

### 1. 데이터 수집 파이프라인 관리

- **지원 소스**: StackOverflow, Reddit, Oppadu
- **수집 제어**: 시작/정지/재시작 기능
- **상태 모니터링**: 실시간 수집 상태 확인
- **오류 처리**: 자동 재시도 및 오류 로깅

### 2. AI 비용 추적

- **실시간 사용량**: 토큰 사용량 및 비용 추적
- **예산 관리**: 월별 예산 설정 및 알림
- **모델별 분석**: 각 AI 모델의 효율성 비교
- **프로바이더 비교**: OpenAI, Anthropic, Google AI 비교

### 3. 시스템 모니터링

- **로그 조회**: 실시간 시스템 로그
- **캐시 관리**: 메모리 캐시 정리
- **데이터셋 관리**: 수집된 데이터 파일 관리

## 클래스 및 서비스

### 1. `AiUsageRecord` 모델

AI 사용량을 추적하는 ActiveRecord 모델:

```ruby
# 사용량 생성
AiUsageRecord.create_from_api_call(
  model_id: 'gpt-4o-mini',
  provider: 'openai',
  cost: 0.001,
  input_tokens: 100,
  output_tokens: 50,
  request_type: :chat
)

# 통계 조회
AiUsageRecord.current_month_stats
AiUsageRecord.budget_utilization_percentage
```

### 2. `AiIntegration::UsageTracker` 서비스

AI 사용량 추적 서비스:

```ruby
tracker = AiIntegration::UsageTracker.new(user: current_user)
tracker.track_openai_usage(model_id: 'gpt-4o-mini', response: response)
```

### 3. `DataPipeline::PipelineController`

데이터 수집 파이프라인 제어:

```ruby
controller = DataPipeline::PipelineController.new
controller.start_collection(['stackoverflow', 'reddit'])
controller.get_pipeline_status
```

## 보안 고려사항

1. **API 인증**: 프로덕션 환경에서는 적절한 API 인증 구현 필요
2. **권한 관리**: 사용자별 접근 권한 설정
3. **데이터 보안**: 민감한 데이터 암호화 저장
4. **API 키 관리**: 환경 변수로 API 키 관리

## 모니터링 및 로깅

- **Rails 로그**: 모든 API 호출 및 오류 로깅
- **사용량 추적**: 모든 AI API 호출 추적
- **성능 모니터링**: 응답 시간 및 처리량 추적
- **예산 알림**: 예산 초과 시 자동 알림

## 문제 해결

### 1. 데이터베이스 연결 오류
```bash
rails db:setup
rails db:migrate
```

### 2. API 키 오류
```bash
# 환경 변수 확인
echo $OPENROUTER_API_KEY
```

### 3. 포트 충돌
```bash
# 다른 포트로 Rails 서버 시작
rails server -p 3001
```

## 향후 개선사항

1. **실시간 알림**: WebSocket을 통한 실시간 상태 업데이트
2. **고급 분석**: 머신러닝 기반 사용량 예측
3. **자동화**: 스케줄링 기반 자동 데이터 수집
4. **확장성**: 마이크로서비스 아키텍처로 확장