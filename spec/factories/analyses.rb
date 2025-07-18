# frozen_string_literal: true

FactoryBot.define do
  factory :analysis do
    association :excel_file
    association :user
    
    detected_errors do
      [
        {
          type: 'formula_error',
          location: 'A1',
          message: 'Invalid formula: #DIV/0!',
          severity: 'high'
        },
        {
          type: 'data_validation',
          location: 'B2',
          message: 'Value exceeds maximum limit',
          severity: 'medium'
        }
      ]
    end
    
    ai_analysis do
      {
        summary: 'Found 2 errors in the Excel file',
        recommendations: [
          'Fix formula in cell A1',
          'Update data validation rule in B2'
        ],
        confidence: 0.95,
        processing_time: 12.5
      }
    end
    
    ai_tier_used { 'tier1' }
    tokens_used { 15 }
    confidence_score { 0.95 }
    
    trait :tier2 do
      ai_tier_used { 'tier2' }
      tokens_used { 45 }
      confidence_score { 0.98 }
    end
    
    trait :low_confidence do
      confidence_score { 0.75 }
    end
    
    trait :high_token_usage do
      tokens_used { 100 }
    end
    
    trait :with_many_errors do
      detected_errors do
        10.times.map do |i|
          {
            type: 'formula_error',
            location: "A#{i + 1}",
            message: "Error in cell A#{i + 1}",
            severity: 'medium'
          }
        end
      end
    end
  end
end