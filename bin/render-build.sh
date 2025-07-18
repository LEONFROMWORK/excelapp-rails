#!/usr/bin/env bash
# exit on error
set -o errexit

# Set SECRET_KEY_BASE for asset precompilation
export SECRET_KEY_BASE=${SECRET_KEY_BASE:-"temporary_build_key_$(date +%s)"}

# Install dependencies
bundle install

# Run database migrations
bundle exec rails db:migrate

# Build Tailwind CSS
bundle exec rails tailwindcss:build

# Precompile assets
bundle exec rails assets:precompile