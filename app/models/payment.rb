# frozen_string_literal: true

class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :payment_intent

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :toss_transaction_id, presence: true, uniqueness: true
  validates :status, presence: true

  enum status: {
    completed: 'completed',
    refunded: 'refunded',
    partially_refunded: 'partially_refunded'
  }

  scope :recent, -> { order(processed_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_payment_method, ->(method) { where(payment_method: method) }

  def display_payment_method
    case payment_method
    when 'card'
      '신용카드'
    when 'bank_transfer'
      '계좌이체'
    when 'virtual_account'
      '가상계좌'
    when 'mobile'
      '휴대폰'
    else
      payment_method&.humanize || '알 수 없음'
    end
  end

  def formatted_amount
    "#{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}원"
  end

  def can_be_refunded?
    completed? && processed_at > 7.days.ago
  end

  def refund_deadline
    processed_at + 7.days
  end
end