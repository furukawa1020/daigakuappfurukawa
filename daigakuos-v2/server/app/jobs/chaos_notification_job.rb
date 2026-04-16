class ChaosNotificationJob < ApplicationJob
  queue_as :notifications

  def perform
    # Focus on users with high chaos who haven't synced recently
    User.where('last_sync_at < ?', 10.minutes.ago).find_each do |user|
      chaos = user.chaos_level
      if chaos > 0.7
        send_crisis_alert(user)
      end
    end
  end

  private

  def send_crisis_alert(user)
    # Use ActionCable to notify if online, or Push Notification if offline
    # For this simulation, we use MokoNativeCommandService
    MokoNativeCommandService.notify!(user, 
      title: "🚨 緊急事態だもこ！ 🚨", 
      body: "あなたのタスク領域がカオスに侵食されているもこ！モンスターの咆哮が聞こえ始めたもこ...！今すぐ戻って浄化（整理）するもこ！🐾👹",
      sound: "roar.mp3"
    )
  end
end
