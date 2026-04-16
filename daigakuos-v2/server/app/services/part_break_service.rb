class PartBreakService
  MONSTERS = {
    'moko_wyvern' => { 
      parts: { 'head' => 'wyvern_fang', 'tail' => 'wyvern_marrow', 'wing' => 'wyvern_scale' },
      difficulty: 1 
    },
    'shadow_behemoth' => { 
      parts: { 'horn' => 'behemoth_horn', 'tail' => 'shadow_gem', 'claw' => 'shadow_claw' },
      difficulty: 2 
    },
    'flame_kirin' => { 
      parts: { 'horn' => 'kirin_azure_horn', 'mane' => 'kirin_thundershadow', 'hoof' => 'kirin_hoof' },
      difficulty: 3 
    }
  }

  def self.process_session!(user, session)
    return [] unless session.duration >= 15
    
    quest = user.hunting_quests.active.first
    return [] unless quest
    
    monster_data = MONSTERS[quest.target_monster]
    return [] unless monster_data
    
    broken_parts = []
    
    # 1. Tail Break: Requires high duration (Cutting through!)
    if session.duration >= 45 && monster_data[:parts].key?('tail')
      broken_parts << { part: 'tail', material: monster_data[:parts]['tail'] }
    end
    
    # 2. Head Break: Requires high focus quality (Precision!)
    if session.quality >= 90 && monster_data[:parts].key?('head')
      broken_parts << { part: 'head', material: monster_data[:parts]['head'] }
    end
    
    if session.quality >= 90 && monster_data[:parts].key?('horn')
      broken_parts << { part: 'horn', material: monster_data[:parts]['horn'] }
    end

    # 3. Rare Drop: Scaling with difficulty and quality
    rare_drop = nil
    if rand < (session.quality / 200.0)
      rare_drop = "plate_#{quest.target_monster}"
    end

    # Save to user inventory
    inventory = user.inventory || {}
    broken_parts.each do |p|
      inventory[p[:material]] = (inventory[p[:material]] || 0) + 1
    end
    inventory[rare_drop] = (inventory[rare_drop] || 0) + 1 if rare_drop
    
    user.update!(inventory: inventory)
    
    # Check if quest is complete (Sum of focused minutes)
    quest.progress ||= 0
    quest.progress += session.duration
    if quest.progress >= quest.required_minutes
      quest.completed!
      ActionCable.server.broadcast("chat_channel", {
        username: "SYSTEM",
        content: "🏆 【#{user.username}】がクエスト『#{quest.target_monster}の狩猟』を達成したもこ！✨",
        timestamp: Time.current.strftime("%H:%M")
      })
    end
    
    broken_parts
  end
end
