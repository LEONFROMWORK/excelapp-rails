# Manual require for lib files to avoid Zeitwerk conflicts
require Rails.root.join('lib', 'result')
require Rails.root.join('lib', 'common_errors')

# Require other lib files
Dir.glob(Rails.root.join('lib', '**', '*.rb')).each do |file|
  next if file.include?('tasks') # Skip rake tasks
  require file
end