class CreateAiFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chat_message, null: false, foreign_key: true
      t.integer :rating
      t.text :feedback_text
      t.integer :ai_tier_used
      t.string :provider
      t.decimal :confidence_score

      t.timestamps
    end
  end
end
