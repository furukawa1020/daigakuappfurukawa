class AnalyticsService
  def self.world_heatmap
    # Returns focus minutes grouped by date for all users
    Session.where('started_at > ?', 30.days.ago)
           .group("DATE(started_at)")
           .sum(:duration)
  end

  def self.rarity_distribution
    # Returns the count of MokoItems grouped by rarity
    MokoItem.group(:rarity).count
  end

  def self.global_stats
    {
      total_focus_hours: (Session.sum(:duration) / 60.0).round(2),
      active_users: User.where('last_sync_at > ?', 24.hours.ago).count,
      total_mokos_collected: MokoItem.count
    }
  end
end
