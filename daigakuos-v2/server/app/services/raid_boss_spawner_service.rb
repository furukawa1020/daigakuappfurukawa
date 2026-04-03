class RaidBossSpawnerService
  # Ensures a global raid boss is always active during game hours.
  
  BOSS_TEMPLATES = [
    { title: "SNSの深淵竜 🐉", hp: 50000, duration: 2.hours },
    { title: "二度寝の魔王 😴", hp: 30000, duration: 1.hour },
    { title: "無計画の混沌獣 🐙", hp: 40000, duration: 90.minutes },
    { title: " procrastinati-on-nator 🤖", hp: 80000, duration: 3.hours }
  ]

  def self.ensure_active_boss
    return if GlobalRaid.active.any?

    template = BOSS_TEMPLATES.sample
    spawn_boss(template)
  end

  def self.spawn_boss(template)
    GlobalRaid.create!(
      title: template[:title],
      max_hp: template[:hp],
      current_hp: template[:hp],
      status: 'active',
      starts_at: Time.current,
      ends_at: Time.current + template[:duration],
      participants_data: {}
    )
    
    # Broadcast new boss to world
    ActionCable.server.broadcast("raid_channel", {
      type: "boss_spawned",
      title: template[:title],
      max_hp: template[:hp],
      ends_at: Time.current + template[:duration],
      message: "新たな魔王が現れた：#{template[:title]} ! 全員で迎え撃てもこ！"
    })
    
    Rails.logger.info "[RaidSpawner] Spawned new boss: #{template[:title]}"
  end
end
