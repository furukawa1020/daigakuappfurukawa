class Web::DashboardController < ActionController::Base
  def index
    @users = User.includes(:sessions, :moko_items).all
    @total_users = User.count
    @total_sessions = Session.count
    @total_focus_minutes = Session.sum(:duration) || 0
    @mokos = MokoTemplate.order(:phase, :required_level)
    
    render layout: false
  end
end
