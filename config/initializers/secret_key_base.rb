# Handle SECRET_KEY_BASE for asset precompilation
# This ensures Rails can initialize during asset precompilation on Render
# without requiring credentials to be available during build time

if Rails.env.production?
  # During asset precompilation, if no SECRET_KEY_BASE is set,
  # use a temporary value. Render will set the real value at runtime.
  if ENV['SECRET_KEY_BASE'].blank? && (defined?(Rails::Console) || Rails.application.config.assets.compile)
    Rails.logger&.info("Using temporary SECRET_KEY_BASE for asset precompilation")
    ENV['SECRET_KEY_BASE'] ||= 'temporary_secret_key_base_for_asset_precompilation_only'
  end
end