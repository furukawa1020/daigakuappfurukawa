class MokoWorldService
  WEATHER_TYPES = %w[sunny focus_storm moko_festival foggy starry_night]
  @@world_status = {
    weather: "sunny",
    event_name: "通常運行もこ",
    started_at: Time.current,
    raid_buff: 1.0,
    raid_buff_ends_at: nil
  }.with_indifferent_access

  def self.current_status
    # Expire buff if time is up
    if @@world_status[:raid_buff_ends_at] && @@world_status[:raid_buff_ends_at] < Time.current
      @@world_status[:raid_buff] = 1.0
      @@world_status[:raid_buff_ends_at] = nil
    end

    raid = GlobalRaid.active.first
    
    # Apply Boss Skill Debuffs
    if raid&.skill_active?
      case raid.active_skill
      when 'shadow_mist'
        @@world_status[:raid_buff] *= 0.5 
        @@world_status[:event_name] = "【警告】#{raid.title}の「影の霧」により集中効率が半減しているもこ！🌫️"
      when 'primal_roar'
        # Visual/Raid damage debuff (logic handled in RaidEngine)
        @@world_status[:event_name] = "【警告】#{raid.title}の「咆哮」が響き渡っているもこ！⚡"
      when 'memory_leak'
        @@world_status[:event_name] = "【警告】#{raid.title}の「メモリリーク」で戦況が混乱しているもこ！🌀"
      end
    end

    @@world_status.merge({
      active_raid: raid,
      current_phase: raid&.current_phase || 1
    })
  end

  def self.trigger_victory_buff!(hours = 3)
    @@world_status[:raid_buff] = 1.3 # 30% XP/Point Bonus
    @@world_status[:raid_buff_ends_at] = Time.current + hours.hours
    
    change_weather!("sunny") # Clear skies for victory
    
    # Notify world!
    ActionCable.server.broadcast("activity_feed", {
      type: "victory_buff_activated",
      message: "レイドボス討伐により、世界中のみんなの集中効率が1.3倍になったもこ！🔥",
      ends_at: @@world_status[:raid_buff_ends_at]
    })
  end

  def self.change_weather!(weather_type = nil)
    weather_type ||= WEATHER_TYPES.sample
    @@world_status = {
      weather: weather_type,
      event_name: event_name_for(weather_type),
      started_at: Time.current
    }.with_indifferent_access
    
    # Broadcast to everyone!
    ActionCable.server.broadcast("activity_feed", {
      type: "world_weather_change",
      status: @@world_status
    })
    
    @@world_status
  end

  private

  def self.event_name_for(type)
    case type
    when "sunny" then "快晴もこ！集中日和だもこ！"
    when "focus_storm" then "集中ストーム発生中！XP1.5倍だもこ！🔥"
    when "moko_festival" then "もこ祭り開催中！プレゼントが届きやすいもこ！🎁"
    when "foggy" then "霧が深いもこ...焦らず進もうもこ。"
    when "starry_night" then "満天の星空だもこ。夜更かししすぎないでねもこ。💤"
    else "謎の現象が発生中だもこ！"
    end
  end
end
