# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  
  # Associations
  has_many :excel_files, dependent: :destroy
  has_many :analyses, dependent: :destroy
  has_many :chat_conversations, dependent: :destroy
  has_many :payment_intents, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_one :subscription, dependent: :destroy
  
  # Enums
  enum :role, { user: 0, admin: 1, super_admin: 2 }
  enum :tier, { free: 0, basic: 1, pro: 2, enterprise: 3 }
  
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Callbacks
  before_create :generate_referral_code
  before_save :downcase_email
  
  # Scopes
  scope :active, -> { where(email_verified: true) }
  scope :by_tier, ->(tier) { where(tier: tier) }
  scope :with_tokens, -> { where('tokens > 0') }
  
  # Instance methods
  def active?
    email_verified?
  end
  
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
  
  def has_active_subscription?
    subscription.present? && subscription.active?
  end
  
  def consume_tokens!(amount)
    raise ::Common::Errors::InsufficientTokensError.new(required: amount, available: tokens) if tokens < amount
    
    decrement!(:tokens, amount)
  end
  
  def add_tokens!(amount)
    increment!(:tokens, amount)
  end
  
  def total_spent
    payments.completed.sum(:amount)
  end
  
  def payment_history
    payments.includes(:payment_intent).recent.limit(10)
  end
  
  def pending_payments
    payment_intents.pending
  end
  
  private
  
  def generate_referral_code
    self.referral_code = loop do
      code = SecureRandom.alphanumeric(8).upcase
      break code unless User.exists?(referral_code: code)
    end
  end
  
  def downcase_email
    self.email = email.downcase
  end
end