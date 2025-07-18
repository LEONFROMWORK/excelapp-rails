class ApplicationController < ActionController::Base
  include Authentication
  
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # CSRF protection
  protect_from_forgery with: :exception
  
  # Authentication
  before_action :authenticate_user!
  
  # Set current attributes for logging and tracking
  before_action :set_current_attributes
  
  private
  
  def set_current_attributes
    Current.request_id = request.uuid
    Current.user_agent = request.user_agent
    Current.ip_address = request.remote_ip
  end
end
