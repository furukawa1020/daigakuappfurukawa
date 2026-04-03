class MokoWorldJob < ApplicationJob
  queue_as :default

  # This job manages the server-wide "living world" events.
  # Should be scheduled (e.g., every hour via Sidekiq/Cron).
  def perform
    Rails.logger.info "[MokoWorldJob] Heartbeat starting..."

    # 1. Random Weather Transition (70% chance to stay, 30% to change)
    if rand < 0.3
      MokoWorldService.change_weather!
      Rails.logger.info "[MokoWorldJob] Weather shifted to #{MokoWorldService.current_status[:weather]}"
    end

    # 2. Raid Boss Lifecycle Check
    GlobalRaidLifecycleJob.perform_now
    
    # 3. Cleanup old raids (Archive defeated/expired older than 24h)
    GlobalRaid.where('ends_at < ?', 24.hours.ago).delete_all
    
    Rails.logger.info "[MokoWorldJob] Heartbeat completed."
  end
end
