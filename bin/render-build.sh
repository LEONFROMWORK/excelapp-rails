#!/usr/bin/env bash
# exit on error
set -o errexit

# Set SECRET_KEY_BASE for asset precompilation if not already set
# Use a temporary key for build process if Render hasn't set one yet
if [ -z "$SECRET_KEY_BASE" ]; then
  export SECRET_KEY_BASE="temporary_key_for_asset_precompilation_$(date +%s)"
fi

# Install dependencies
bundle install

# Run database migrations
bundle exec rails db:migrate

# Build Tailwind CSS
bundle exec rails tailwindcss:build

# Precompile assets
bundle exec rails assets:precompile