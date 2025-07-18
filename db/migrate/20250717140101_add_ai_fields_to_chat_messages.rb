class AddAiFieldsToChatMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_messages, :ai_tier_used, :integer
    add_column :chat_messages, :confidence_score, :decimal
    add_column :chat_messages, :provider, :string
    add_column :chat_messages, :user_rating, :integer
    add_column :chat_messages, :user_feedback, :text
  end
end
