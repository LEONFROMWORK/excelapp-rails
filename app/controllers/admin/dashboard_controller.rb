# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    before_action :require_admin!
    
    def index
      @total_users = User.count
      @total_files = ExcelFile.count
      @total_analyses = Analysis.count
      @recent_users = User.recent.limit(5)
      @recent_files = ExcelFile.recent.limit(5)
      @recent_analyses = Analysis.recent.limit(5)
    end
  end
end