#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# Run database migrations
bundle exec rails db:migrate

# Build Tailwind CSS
bundle exec rails tailwindcss:build

# Precompile assets
bundle exec rails assets:precompile