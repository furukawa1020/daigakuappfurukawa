class CommunityReportJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[CommunityReport] Generating daily global statistics..."
    
    total_users = User.count
    total_minutes = Session.sum(:duration) || 0
    top_moko = MokoItem.group(:item_id).count.max_by { |_, v| v }&.first
    
    # Store in a global cache or a specialized 'GlobalStat' model
    Rails.cache.write("global_report_#{Date.today}", {
      user_count: total_users,
      total_focus_time: total_minutes,
      popular_moko: top_moko,
      generated_at: Time.current
    }, expires_in: 48.hours)
    
    # Broadcast to Activity Feed
    ActionCable.server.broadcast("activity_feed_channel", {
      type: "community_report",
      message: "本日のコミュニティ統計: 累計集中時間 #{total_minutes}分達成！現在の人気No.1モコは #{top_moko} です。✨",
      timestamp: Time.current
    })
  end
end
