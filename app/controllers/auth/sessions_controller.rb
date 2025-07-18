# frozen_string_literal: true

module Auth
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:new, :create]
    
    def new
      redirect_to root_path if user_signed_in?
    end
    
    def create
      user = User.find_by(email: params[:email]&.downcase)
      
      if user&.authenticate(params[:password])
        login(user)
        redirect_to root_path, notice: "Welcome back, #{user.name}!"
      else
        flash.now[:alert] = "Invalid email or password"
        render :new, status: :unprocessable_entity
      end
    end
    
    def destroy
      logout
      redirect_to root_path, notice: "Successfully logged out"
    end
  end
end