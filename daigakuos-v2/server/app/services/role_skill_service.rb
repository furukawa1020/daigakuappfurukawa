class RoleSkillService
  SKILLS = {
    'tank' => { 
      id: 'aegis_shield', 
      name: 'イージスの盾', 
      desc: 'ボスの物理ギミックを10分間相殺し、パーティの防御を固めるもこ！',
      duration: 10.minutes
    },
    'healer' => { 
      id: 'sanctuary', 
      name: 'サンクチュアリ', 
      desc: 'パーティ全員のXP獲得量を5分間2倍にし、呪いを浄化するもこ！',
      duration: 5.minutes
    },
    'dps' => { 
      id: 'limit_break', 
      name: 'リミットブレイク', 
      desc: '10分間、全ての攻撃がクリティカルヒットになるもこ！最強だもこ！',
      duration: 10.minutes
    }
  }

  def self.use_skill!(user)
    return { success: false, error: 'まだスキルは使えないもこ！' } unless user.can_use_skill?

    skill = SKILLS[user.role]
    return { success: false, error: 'スキルが見つからないもこ...' } unless skill

    # 1. Update User cooldown
    user.update!(last_skill_used_at: Time.current)

    # 2. Apply immediate effects based on role
    case user.role
    when 'healer'
      # Healers immediately clear the world curse for everyone? Or just party?
      # Let's say it clears for everyone to make Healers feel like "World Saviors"
      GlobalRaid.active.each(&:clear_skill!)
    when 'tank'
      # Tanks clear current boss gimmick (if any)
      raid = GlobalRaid.active.first
      if raid&.gimmick_active?
        raid.update!(active_gimmick: nil, gimmick_ends_at: nil)
        ActionCable.server.broadcast("raid_channel", { type: "gimmick_broken", message: "🛡️ Tankのスキルによってボスのギミック【#{raid.active_gimmick}】が破壊されたもこ！" })
      end
    end

    # 3. Broadcast to Party/World
    ActionCable.server.broadcast("chat_channel", {
      username: "SYSTEM",
      content: "🛡️⚡ 【#{user.username}】が奥義『#{skill[:name]}』を発動！ #{skill[:desc]}",
      timestamp: Time.current.strftime("%H:%M")
    })

    # Add a temporary Role Buff to the world/party state
    # For now, we'll track this in a simple global or user-specific way
    # (In a real app, you'd use a dedicated ActiveBuff model, but for this MMO engine 
    # we can use a dynamic cache/store or just check timestamps in calculations)

    { success: true, skill_name: skill[:name], message: "#{skill[:name]} を発動したもこ！" }
  end

  def self.is_buff_active?(user, skill_id)
    # Check if the user used the specific skill recently
    return false unless user.last_skill_used_at
    skill = SKILLS[user.role]
    return false if skill[:id] != skill_id
    
    user.last_skill_used_at + skill[:duration] > Time.current
  end
end
