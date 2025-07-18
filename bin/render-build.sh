#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# Run database migrations
bundle exec rails db:migrate

# Precompile assets
bundle exec rails assets:precompile

# Clean up
bundle exec rails assets:clean