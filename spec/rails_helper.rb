# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'factory_bot_rails'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  
  # FactoryBot configuration
  config.include FactoryBot::Syntax::Methods
  
  # Additional includes
  config.include ActiveSupport::Testing::TimeHelpers
  
  # Database cleaner configuration
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
  
  # Rails specific configurations
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
  
  # Mock external API calls by default
  config.before(:each) do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-key')
    allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return('test-key')
    allow(ENV).to receive(:[]).with('GOOGLE_API_KEY').and_return('test-key')
    allow(ENV).to receive(:[]).with('TOSS_CLIENT_KEY').and_return('test-key')
    allow(ENV).to receive(:[]).with('TOSS_SECRET_KEY').and_return('test-key')
  end
end