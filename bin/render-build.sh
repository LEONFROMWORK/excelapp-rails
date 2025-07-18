#!/usr/bin/env bash
# exit on error
set -o errexit

# Set SECRET_KEY_BASE for asset precompilation if not already set
export SECRET_KEY_BASE=${SECRET_KEY_BASE:-$(bundle exec rails secret)}

# Install dependencies
bundle install

# Run database migrations
bundle exec rails db:migrate

# Build Tailwind CSS
bundle exec rails tailwindcss:build

# Precompile assets
bundle exec rails assets:precompile