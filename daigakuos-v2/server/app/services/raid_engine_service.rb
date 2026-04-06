class RaidEngineService
  # Processes damage against the global raid boss based on user session duration.
  # Handles concurrency by using database record locking.

  def self.process_damage!(user, duration)
    return nil if duration <= 0

    # Base damage: 1 minute = 10 damage
    damage = duration * 10

    # Party Synergy: Calculate how many PARTY members are active recently
    party = user.party
    if party
      active_party_members = party.users.where.not(id: user.id).where('last_sync_at > ?', 15.minutes.ago).count
      party_multiplier = 1.0 + (active_party_members * 0.2) # 20% bonus per active party member
    else
      party_multiplier = 1.0
    end
    
    # Global Activity: Still apply a small global bonus
    active_users_count = User.where('last_sync_at > ?', 15.minutes.ago).count
    global_multiplier = 1.0 + (active_users_count * 0.05)
    
    multiplier = party_multiplier * global_multiplier
    
    # Phase 40: Role Specific Multipliers
    role_multiplier = 1.0
    is_crit = false

    case user.role
    when 'tank'
      # Tanks boost the whole party's synergy more effectively
      party_multiplier *= 1.3 
    when 'dps'
      # DPS dealt more raw damage + Crit chance
      role_multiplier = 1.5
      if rand < 0.1 # 10% Critical Hit chance
        role_multiplier *= 2.0
        is_crit = true
      end
    when 'healer'
      # Healers deal normal damage but will provide XP bonuses elsewhere
      role_multiplier = 1.0
    end

    # World Buff: Apply bonus if everyone is currently buffed from last victory
    world_multiplier = MokoWorldService.current_status[:raid_buff] || 1.0
    
    final_damage = (damage * multiplier * role_multiplier * world_multiplier).to_i

    GlobalRaid.transaction do
      # Fetch the active raid and lock it for updating (pessimistic locking) to prevent race conditions
      raid = GlobalRaid.active.lock.first
      return nil unless raid

      # Update participant data
      current_user_damage = (raid.participants_data[user.username] || 0)
      raid.participants_data[user.username] = current_user_damage + final_damage
      raid.participants_data_will_change!
      
      # Apply damage
      new_hp = [raid.current_hp - final_damage, 0].max
      raid.current_hp = new_hp

      if new_hp == 0 && raid.status == 'active'
        raid.status = 'defeated'
        # Distribute rewards
        distribute_rewards(raid)
      else
        # Phase 40: Check for phase transition
        raid.update_phase!
      end

      raid.save!

      # Broadcast real-time update
      broadcast_raid_status(raid, user.username, final_damage, is_crit, user.role)

      return { damage: final_damage, boss_hp: new_hp, status: raid.status, is_crit: is_crit }
    end
  rescue StandardError => e
    Rails.logger.error "[RaidEngine] Failed to process damage: #{e.message}"
    nil
  end

  private

  def self.distribute_rewards(raid)
    Rails.logger.info "[RaidEngine] Boss #{raid.title} defeated! Distributing rewards..."
    
    # Sort participants by damage contribution
    sorted_participants = raid.participants_data.to_a.sort_by { |_, dmg| -dmg }
    
    sorted_participants.each_with_index do |(username, dmg), index|
      user = User.find_by(username: username)
      next unless user

      # Top 3 get Legendary drops
      if index < 3
        user.add_material!('dragon_scale', rand(1..3))
        user.add_material!('star_dust', 5)
        MokoNativeCommandService.notify!(user, title: "レイドボス討伐！🎖️", body: "トップ貢献者として伝説の素材を手に入れた！")
      else
        user.add_material!('moko_stone', rand(5..10))
        MokoNativeCommandService.notify!(user, title: "レイドボス討伐！", body: "ボスを無事倒したもこ！報酬ゲット！")
      end
    end
    
    # Broadcast final report
    RaidReportService.broadcast_final_report(raid)
    
    # Activate Global Victory Buff (30% increase for everyone)
    MokoWorldService.trigger_victory_buff!(3)

    # Broadcast defeat
    ActionCable.server.broadcast("raid_channel", {
      type: "boss_defeated",
      message: "#{raid.title} が討伐されました！🎉 全員に3時間の集中バフが付与されたもこ！",
      leaderboard: sorted_participants.first(5)
    })
  end

  def self.broadcast_raid_status(raid, attacker_username, damage, is_crit = false, role = 'dps')
    ActionCable.server.broadcast("raid_channel", {
      type: "damage_dealt",
      attacker: attacker_username,
      attacker_role: role,
      damage: damage,
      is_crit: is_crit,
      current_hp: raid.current_hp,
      max_hp: raid.max_hp,
      health_percentage: raid.health_percentage,
      current_phase: raid.current_phase
    })
  end
end
