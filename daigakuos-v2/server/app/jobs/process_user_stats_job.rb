class ProcessUserStatsJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    Rails.logger.info "[ActiveJob] Processing deep analytics for User ##{user.id} asynchronously..."

    total_duration = user.sessions.sum(:duration) || 0
    
    # 1. Advanced Reward Logic (Simulating heavy DB queries)
    if total_duration >= 6000 # 100 hours
      unless user.moko_items.exists?(item_id: 'moko_king')
        user.moko_items.create!(item_id: 'moko_king', rarity: 'Legendary', unlocked_at: Time.current)
        Rails.logger.info "[ActiveJob] 👑 Unlocked King Moko for User ##{user.id}!"
      end
    end

    # 2. Ranking Cache Invalidation
    # This ensures global leaderboard stays fresh after user data changes
    RankingService.clear_cache
    Rails.logger.info "[ActiveJob] 🏅 Ranking cache cleared after User ##{user.id} update."

    # 3. ActionMailer: Queueing weekly digest emails on Fridays
    if Time.current.friday?
      UserMailer.weekly_report(user).deliver_later
      Rails.logger.info "[ActionMailer] Queued weekly digest email for User ##{user.id}"
    end
    
    # 4. ActionCable: Broadcast real-time activity
    ActionCable.server.broadcast("activity_feed_channel", {
      user: user.username,
      type: "sync_completed",
      total_duration: total_duration,
      timestamp: Time.current
    })
  end
end
