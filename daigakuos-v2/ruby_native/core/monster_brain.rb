# ruby_native/core/monster_brain.rb
require_relative 'action_patterns'

class MonsterBrain
  # 🍖 Biological Simulation: Hunger, Fatigue, Alertness
  # 🧠 Predatory Pattern Matching: Markov-style focus prediction

  BEHAVIOR_MODES = {
    grazing: { name: "良好", risk: 0.1, color: "green" },
    hunting: { name: "追跡", risk: 0.5, color: "orange" },
    starving: { name: "捕食", risk: 0.8, color: "red" },
    enraged: { name: "逆鱗", risk: 1.2, color: "purple" }
  }

  def self.tick(raid_state, elapsed_hours, user_sessions, env_state = {})
    # 🍖 Metabolism: Monster grows hungry and tired over time
    hp_ratio = raid_state[:current_hp].to_f / raid_state[:max_hp]
    
    # Hunger: Increases based on elapsed time and lack of user focus
    hunger_gain = 5.0 + (elapsed_hours * 10.0)
    raid_state[:hunger] = [(raid_state[:hunger] || 0.0) + hunger_gain, 100.0].min
    
    # Fatigue: Decreases over time unless in active combat
    fatigue_decay = elapsed_hours * 5.0
    raid_state[:fatigue] = [(raid_state[:fatigue] || 0.0) - fatigue_decay, 0.0].max
    
    # 🧠 Predatory Prediction (Markov Chain)
    current_hour = Time.now.hour
    raid_state[:alertness] = calculate_alertness(current_hour, user_sessions)
    
    # 🧬 Update Behavioral Mode
    update_behavior!(raid_state, env_state)
    
    raid_state
  end

  def self.update_behavior!(raid_state, env_state)
    toxins = env_state[:toxins] || 0.0
    hp_ratio = raid_state[:current_hp].to_f / raid_state[:max_hp]
    
    # Priority State Logic
    if toxins > 80.0 || hp_ratio < 0.2
      raid_state[:behavior_mode] = :enraged
    elsif raid_state[:hunger] > 70.0
      raid_state[:behavior_mode] = :starving
    elsif raid_state[:alertness] > 0.6
      raid_state[:behavior_mode] = :hunting
    else
      raid_state[:behavior_mode] = :grazing
    end
  end

  def self.calculate_alertness(hour, sessions)
    return 0.1 if sessions.nil? || sessions.empty?
    # Simple Markov: P(Focus | Hour)
    focus_history = sessions.select { |s| s[:started_at] && DateTime.parse(s[:started_at]).hour == hour }
    probability = focus_history.count / 7.0 
    (1.0 - probability).clamp(0.1, 1.0)
  end

  def self.decide_action(raid_state, entropy)
    mode = raid_state[:behavior_mode] || :grazing
    mode_info = BEHAVIOR_MODES[mode]
    
    # Inherit base patterns
    base_action = ActionPatterns.select_action(raid_state[:current_phase], entropy)
    
    # 🧬 Behavioral Overrides & Contextual Naming
    case mode
    when :enraged
      action = ActionPatterns::ACTIONS[:chaos_breath].merge(
        name: "【#{mode_info[:name]}】極限の滅魂ブレス",
        damage_mult: 1.5
      )
    when :starving
      action = ActionPatterns::ACTIONS[:data_void].merge(
        name: "【#{mode_info[:name]}】魂の捕食",
        damage_mult: 1.2
      )
    when :hunting
      action = base_action.merge(
        name: "【#{mode_info[:name]}】予測された打撃",
        damage_mult: 1.1
      )
    else
      action = base_action.merge(name: "【#{mode_info[:name]}】#{base_action[:name]}")
    end
    
    action
  end
end
