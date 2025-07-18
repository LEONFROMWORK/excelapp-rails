# frozen_string_literal: true

module Auth
  class RegistrationsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:new, :create]
    
    def new
      @user = User.new
      redirect_to root_path if user_signed_in?
    end
    
    def create
      @user = User.new(user_params)
      @user.referred_by = params[:referral_code] if params[:referral_code].present?
      
      if @user.save
        # Award referral bonus if applicable
        award_referral_bonus(@user) if @user.referred_by.present?
        
        login(@user)
        redirect_to root_path, notice: "Welcome to ExcelApp! You have #{@user.tokens} free tokens to start."
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    private
    
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
    
    def award_referral_bonus(new_user)
      referrer = User.find_by(referral_code: new_user.referred_by)
      return unless referrer
      
      # Award tokens to both users
      referrer.add_tokens!(500)
      new_user.add_tokens!(200)
      
      # You might want to create a referral record here for tracking
    end
  end
end