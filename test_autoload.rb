# Test script to check autoloading
require_relative 'config/environment'

puts "Testing autoload..."

begin
  puts "Loading Ai module..."
  puts Ai.inspect
  
  puts "Loading ResponseValidation module..."
  puts Ai::ResponseValidation.inspect
  
  puts "Loading AiResponseValidator class..."
  puts Ai::ResponseValidation::AiResponseValidator.inspect
  
  puts "SUCCESS: All classes loaded correctly!"
rescue => e
  puts "ERROR: #{e.class}: #{e.message}"
  puts e.backtrace.first(5)
end