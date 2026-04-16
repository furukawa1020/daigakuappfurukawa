class MonsterAIEngine
  STATES = {
    normal: { name: '通常', damage_mult: 1.0, speed: 1.0, icon: '😐' },
    enraged: { name: '怒り', damage_mult: 1.5, speed: 1.5, icon: '🔥' },
    exhausted: { name: '疲労', damage_mult: 0.8, speed: 0.5, icon: '🤤' },
    sleeping: { name: '睡眠', damage_mult: 2.0, speed: 0.0, icon: '💤' },
    limping: { name: '瀕死', damage_mult: 1.0, speed: 0.8, icon: '💧' }
  }

  def self.get_current_state(raid)
    # This logic would normally be state-driven in the database
    # For now, let's derive it from current HP and random factors
    hp_ratio = raid.current_hp.to_f / raid.max_hp
    
    return :sleeping if hp_ratio < 0.05
    return :limping if hp_ratio < 0.15
    
    # 50% HP threshold for Enraged/Exhausted cycle
    if hp_ratio < 0.50
      # Use a time-based cycle for demonstration
      cycle_time = (Time.current.to_i / 60) % 10 # 10 minute cycle
      if cycle_time < 5
        :enraged
      elsif cycle_time < 7
        :exhausted
      else
        :normal
      end
    else
      :normal
    end
  end

  def self.get_state_modifiers(raid)
    state_key = get_current_state(raid)
    STATES[state_key]
  end

  def self.broadcast_state!(raid)
    state = get_state_modifiers(raid)
    ActionCable.server.broadcast("raid_channel", {
      type: "boss_state_change",
      state_name: state[:name],
      message: "⚠️ ボスが【#{state[:name]}】状態になったもこ！ #{state[:icon]}",
      modifiers: state
    })
  end

  # Phase 50: Action Selection
  def self.decide_action(raid)
    global_entropy = MokoWorldService.calculate_global_entropy
    ActionPatternService.select_action(raid, global_entropy)
  end
end
