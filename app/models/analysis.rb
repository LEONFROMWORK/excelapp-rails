# frozen_string_literal: true

class Analysis < ApplicationRecord
  # Associations
  belongs_to :excel_file
  belongs_to :user
  
  # Enums
  enum :ai_tier_used, { rule_based: 0, tier1: 1, tier2: 2 }
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }
  
  # Validations
  validates :detected_errors, presence: true
  validates :ai_tier_used, presence: true
  validates :tokens_used, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :confidence_score, numericality: { in: 0..1 }, allow_nil: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: :completed) }
  scope :by_tier, ->(tier) { where(ai_tier_used: tier) }
  scope :high_confidence, -> { where('confidence_score >= ?', 0.85) }
  
  # Callbacks
  before_save :calculate_counts
  
  # Instance methods
  def successful?
    completed? && error_count.positive?
  end
  
  def fix_rate
    return 0 if error_count.zero?
    
    ((fixed_count.to_f / error_count) * 100).round(2)
  end
  
  def tier_name
    case ai_tier_used
    when 'tier1' then 'Basic AI (GPT-3.5/Haiku)'
    when 'tier2' then 'Advanced AI (GPT-4/Opus)'
    else 'Rule-based'
    end
  end
  
  def estimated_time_saved
    # Rough estimate: 2 minutes per error fixed manually
    (fixed_count * 2.0).round(1)
  end
  
  private
  
  def calculate_counts
    if detected_errors.is_a?(Array)
      self.error_count = detected_errors.size
    end
    
    if corrections.is_a?(Array)
      self.fixed_count = corrections.size
    end
  end
end