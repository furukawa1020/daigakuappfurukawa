class ProcessUserStatsJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    Rails.logger.info "[ActiveJob] Processing deep analytics for User ##{user.id} asynchronously..."

    # 0. Mood Refresh
    user.update_moko_mood!
    
    # 0.1 Material Drop (Meaningful rewards)
    if (user.sessions.last&.quality.to_i || 0) >= 4
      user.add_material!("moko_stone", rand(1..3))
      user.add_material!("star_dust", 1) if rand > 0.7
      MokoNativeCommandService.vibrate!(user, pattern: 'light')
    end
    
    # 0.2 Moko Expeditions (Quest Progress & Boss Battles)
    last_session = user.sessions.last
    if last_session
      expedition_result = ExpeditionEngineService.process_session!(user, last_session)
      if expedition_result
        Rails.logger.info "[ActiveJob] ⚔️ Expedition #{expedition_result[:status]}: Dealt #{expedition_result[:damage]} damage!"
        
        if expedition_result[:status] == 'completed'
          MokoNativeCommandService.vibrate!(user, pattern: 'heavy')
          MokoNativeCommandService.notify!(user, title: "クエスト達成🎉", body: "ボスを討伐したもこ！報酬をゲットしたよ！")
          MokoNativeCommandService.play_sound!(user, sound_name: 'quest_clear.mp3')
        end
      end
    end
    
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
    RankingService.invalidate_cache
    Rails.logger.info "[ActiveJob] 🏅 Ranking cache cleared after User ##{user.id} update."

    # 3. ActionMailer: Queueing weekly digest emails on Fridays
    if Time.current.friday?
      UserMailer.weekly_report(user).deliver_later
      Rails.logger.info "[ActionMailer] Queued weekly digest email for User ##{user.id}"
    end
    
    # 4. Moko Whisper Generation
    # Generates a new personalized message based on the user's focus patterns
    MokoWhisperJob.perform_later(user.id)

    # 5. Moko Party Detection
    # If other users synced in the last 10 minutes, trigger a "Party" event
    active_users = User.where('last_sync_at > ?', 10.minutes.ago).where.not(id: user.id)
    if active_users.any?
      ActivityFeedChannel.broadcast_moko_party(active_users + [user])
      # Also trigger a gift from the current user's moko
      MokoGiftJob.perform_later(user.id)
      MokoNativeCommandService.vibrate!(user, pattern: 'medium')
      MokoNativeCommandService.notify!(user, title: "モコパーティ開始！", body: "他のモコたちが集まってきたもこ！")
    end

    # 6. ActionCable: Broadcast individual sync
    ActionCable.server.broadcast("activity_feed_channel", {
      user: user.username,
      type: "sync_completed",
      total_duration: total_duration,
      timestamp: Time.current
    })
  end
end
