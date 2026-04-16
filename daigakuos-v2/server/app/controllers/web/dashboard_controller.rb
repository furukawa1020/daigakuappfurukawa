class Web::DashboardController < ActionController::Base
  def index
    @users = User.includes(:sessions, :moko_items).all.map do |u|
      evolution = MokoEvolutionService.check_evolution(u)
      { user: u, evolution: evolution }
    end
    @total_users = User.count
    @total_sessions = Session.count
    @total_focus_minutes = Session.sum(:duration) || 0
    @mokos = MokoTemplate.order(:phase, :required_level)
    @recent_perf = Rails.cache.read("recent_perf") || []
    @active_raid = GlobalRaid.active.first
    
    render layout: false
  end
end
