class CreateAiProviderMetrics < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_provider_metrics do |t|
      t.string :provider
      t.string :model
      t.integer :tier
      t.integer :total_requests
      t.integer :total_rating
      t.decimal :average_rating
      t.integer :positive_feedback_count
      t.integer :negative_feedback_count

      t.timestamps
    end
  end
end
