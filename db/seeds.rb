# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create test users
puts "Creating test users..."

# Admin user
admin = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "Admin User"
  user.password = "password123"
  user.role = "admin"
  user.tier = "enterprise"
  user.tokens = 10000
  user.email_verified = true
end

# Regular users
user1 = User.find_or_create_by!(email: "user1@example.com") do |user|
  user.name = "John Doe"
  user.password = "password123"
  user.role = "user"
  user.tier = "pro"
  user.tokens = 2000
  user.email_verified = true
end

user2 = User.find_or_create_by!(email: "user2@example.com") do |user|
  user.name = "Jane Smith"
  user.password = "password123"
  user.role = "user"
  user.tier = "basic"
  user.tokens = 500
  user.email_verified = true
end

user3 = User.find_or_create_by!(email: "user3@example.com") do |user|
  user.name = "Bob Johnson"
  user.password = "password123"
  user.role = "user"
  user.tier = "free"
  user.tokens = 100
  user.email_verified = false
end

puts "Created #{User.count} users"

# Create sample Excel files and analyses for demonstration
puts "Creating sample Excel files and analyses..."

# For user1
3.times do |i|
  file = user1.excel_files.create!(
    original_name: "sales_report_202#{i}.xlsx",
    file_path: "/fake/path/sales_report_202#{i}.xlsx",
    file_size: rand(1_000_000..5_000_000),
    status: "completed",
    sheet_count: rand(1..5),
    row_count: rand(100..10000),
    column_count: rand(10..50),
    file_format: ".xlsx"
  )
  
  analysis = file.analyses.create!(
    user: user1,
    detected_errors: [
      { type: "formula_error", cell: "A#{rand(1..100)}", message: "Invalid formula reference" },
      { type: "data_validation", cell: "B#{rand(1..100)}", message: "Value out of range" }
    ],
    ai_analysis: { summary: "Found #{rand(5..20)} errors in formulas and data validation" },
    corrections: [
      { cell: "A10", original: "=SUM(A1:A9", corrected: "=SUM(A1:A9)" }
    ],
    ai_tier_used: ["tier1", "tier2"].sample,
    confidence_score: rand(0.7..0.95).round(2),
    tokens_used: rand(100..500),
    cost: rand(0.01..0.50).round(6),
    status: "completed",
    error_count: rand(5..20),
    fixed_count: rand(3..15),
    analysis_summary: "Successfully analyzed and corrected formula errors and data validation issues."
  )
end

# For user2
2.times do |i|
  file = user2.excel_files.create!(
    original_name: "inventory_#{i + 1}.xlsx",
    file_path: "/fake/path/inventory_#{i + 1}.xlsx",
    file_size: rand(500_000..2_000_000),
    status: ["processing", "completed"].sample,
    sheet_count: rand(1..3),
    row_count: rand(50..5000),
    column_count: rand(5..30),
    file_format: ".xlsx"
  )
  
  if file.completed?
    analysis = file.analyses.create!(
      user: user2,
      detected_errors: [
        { type: "circular_reference", cells: ["C5", "D10"], message: "Circular reference detected" }
      ],
      ai_analysis: { summary: "Detected circular references and formatting issues" },
      corrections: [],
      ai_tier_used: "tier1",
      confidence_score: rand(0.8..0.9).round(2),
      tokens_used: rand(50..200),
      cost: rand(0.005..0.10).round(6),
      status: "completed",
      error_count: rand(2..10),
      fixed_count: rand(1..5),
      analysis_summary: "Analysis complete with partial corrections applied."
    )
  end
end

puts "Created #{ExcelFile.count} Excel files"
puts "Created #{Analysis.count} analyses"

# Create sample chat conversations
puts "Creating sample chat conversations..."

conv1 = user1.chat_conversations.create!(
  title: "Help with financial report",
  message_count: 5,
  total_tokens_used: 450
)

conv2 = user2.chat_conversations.create!(
  title: "Generate inventory template",
  message_count: 3,
  total_tokens_used: 320
)

puts "Created #{ChatConversation.count} chat conversations"

# Create sample subscriptions
puts "Creating sample subscriptions..."

Subscription.create!(
  user: user1,
  plan_type: "pro",
  status: "active",
  starts_at: 1.month.ago,
  ends_at: 11.months.from_now,
  amount: 29900,
  payment_method: "card"
)

Subscription.create!(
  user: user2,
  plan_type: "basic",
  status: "active",
  starts_at: 2.weeks.ago,
  ends_at: 1.month.from_now,
  amount: 9900,
  payment_method: "card"
)

puts "Created #{Subscription.count} subscriptions"

puts "\nSeed data created successfully!"
puts "\nYou can log in with:"
puts "  Admin: admin@example.com / password123"
puts "  User 1: user1@example.com / password123"
puts "  User 2: user2@example.com / password123"
puts "  User 3: user3@example.com / password123"
