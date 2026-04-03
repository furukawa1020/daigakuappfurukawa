class GlobalRaidLifecycleJob < ApplicationJob
  queue_as :default

  # This job should be scheduled to run every 10-15 minutes or triggered after a sync.
  def perform
    Rails.logger.info "[RaidLifecycle] Checking for raid boss status..."

    # 1. Expire bosses that have exceeded their ends_at
    expired_raids = GlobalRaid.active.where('ends_at < ?', Time.current)
    expired_raids.each do |raid|
      raid.update!(status: 'expired')
      Rails.logger.info "[RaidLifecycle] Raid #{raid.title} expired."
      
      ActionCable.server.broadcast("raid_channel", {
        type: "boss_expired",
        message: "#{raid.title} は逃げ出したもこ... 今回は討伐ならずもこ。",
        raid_title: raid.title
      })
    end

    # 2. Ensure an active boss exists
    RaidBossSpawnerService.ensure_active_boss
    
    # 3. Schedule next check if not using a cron-like scheduler
    # GlobalRaidLifecycleJob.set(wait: 15.minutes).perform_later
  end
end
