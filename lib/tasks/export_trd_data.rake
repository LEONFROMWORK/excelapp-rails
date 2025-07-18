namespace :knowledge do
  desc "Export knowledge threads in BigData TRD format"
  task export_trd: :environment do
    puts "🚀 Starting BigData TRD format export..."

    # 설정
    output_dir = Rails.root.join("exports")
    FileUtils.mkdir_p(output_dir)

    timestamp = Time.current.strftime("%Y%m%d_%H%M")
    filename = "knowledge_trd_export_#{timestamp}.json"
    output_path = output_dir.join(filename)

    # 데이터 수집
    threads = KnowledgeThread.active.includes(:source_metadata)

    puts "📊 Found #{threads.count} active knowledge threads"

    # TRD 형식으로 변환
    qa_data = threads.map(&:to_trd_format)

    # 메타데이터 생성
    metadata = {
      exportedAt: Time.current.iso8601,
      version: "1.0",
      format: "BigData_TRD",
      description: "ExcelApp Rails knowledge base export in BigData TRD format",
      statistics: {
        totalThreads: threads.count,
        sources: threads.group(:source).count,
        categories: threads.group(:category).count,
        qualityStats: {
          averageScore: threads.average(:quality_score)&.round(2) || 0.0,
          highQuality: threads.high_quality.count,
          redditOpConfirmed: threads.op_confirmed_reddit.count,
          stackoverflowAccepted: threads.where("source_metadata->>'isAccepted' = 'true'").count
        }
      },
      collectionPeriod: {
        from: threads.minimum(:created_at)&.iso8601,
        to: threads.maximum(:created_at)&.iso8601
      }
    }

    # BigData TRD 표준 구조로 출력
    export_data = {
      metadata: metadata,
      qaData: qa_data
    }

    # 파일 저장
    File.write(output_path, JSON.pretty_generate(export_data))

    puts "✅ Export completed!"
    puts "📁 File saved: #{output_path}"
    puts "📊 Statistics:"
    puts "   - Total QA pairs: #{qa_data.length}"
    puts "   - Reddit threads: #{metadata[:statistics][:sources]['reddit'] || 0}"
    puts "   - Stack Overflow threads: #{metadata[:statistics][:sources]['stackoverflow'] || 0}"
    puts "   - Average quality: #{metadata[:statistics][:qualityStats][:averageScore]}"
    puts ""
    puts "🔄 To sync with ExcelApp Next.js:"
    puts "   1. Copy #{filename} to excelapp/data/"
    puts "   2. Upload via admin panel: /admin/knowledge-base"
    puts "   3. Or use sync script: npm run sync-knowledge"
  end

  desc "Export knowledge threads in JSONL format (for BigData compatibility)"
  task export_jsonl: :environment do
    puts "🚀 Starting JSONL format export for BigData compatibility..."

    output_dir = Rails.root.join("exports")
    FileUtils.mkdir_p(output_dir)

    timestamp = Time.current.strftime("%Y%m%d_%H%M")
    filename = "rails_knowledge_#{timestamp}.jsonl"
    output_path = output_dir.join(filename)

    threads = KnowledgeThread.active

    puts "📊 Found #{threads.count} active knowledge threads"

    File.open(output_path, "w") do |file|
      threads.find_each do |thread|
        file.puts(thread.to_trd_format.to_json)
      end
    end

    puts "✅ JSONL export completed!"
    puts "📁 File saved: #{output_path}"
    puts "📊 Total lines: #{threads.count}"
    puts ""
    puts "🔄 This file is compatible with BigData collection system"
    puts "   - Can be merged with reddit_YYYYMMDD.jsonl files"
    puts "   - Use BigData merge utilities for combined datasets"
  end

  desc "Generate sample TRD data for testing"
  task generate_sample: :environment do
    puts "🧪 Generating sample TRD data for testing..."

    # 샘플 데이터 생성
    sample_threads = [
      {
        external_id: "sample_001",
        source: "manual",
        title: "VLOOKUP 함수 사용법",
        question_content: "VLOOKUP 함수를 사용해서 다른 시트의 데이터를 가져오고 싶습니다.",
        answer_content: "VLOOKUP(찾을값, 범위, 열번호, 정확히일치여부)를 사용하세요. 예: =VLOOKUP(A2,Sheet2!A:C,3,FALSE)",
        category: "formula_functions",
        quality_score: 8.5,
        votes: 25,
        op_confirmed: true,
        source_url: "https://example.com/sample1"
      },
      {
        external_id: "sample_002",
        source: "manual",
        title: "피벗테이블 만들기",
        question_content: "대량의 데이터를 요약하고 분석하려면 어떻게 해야 하나요?",
        answer_content: "피벗테이블을 사용하세요. 데이터 선택 > 삽입 > 피벗테이블로 만들 수 있습니다.",
        category: "pivot_tables",
        quality_score: 9.2,
        votes: 40,
        op_confirmed: true,
        source_url: "https://example.com/sample2"
      }
    ]

    created_count = 0
    sample_threads.each do |thread_data|
      thread = KnowledgeThread.find_or_create_by(
        external_id: thread_data[:external_id],
        source: thread_data[:source]
      ) do |t|
        t.assign_attributes(thread_data.except(:external_id, :source))
        t.processed_at = Time.current
      end

      if thread.persisted?
        created_count += 1
        puts "✅ Created: #{thread.title}"
      end
    end

    puts "🎉 Generated #{created_count} sample threads"
    puts "🔄 Run 'rails knowledge:export_trd' to export in TRD format"
  end
end
