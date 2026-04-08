# ruby_native/core/monster_brain.rb
require_relative 'action_patterns'

class MonsterBrain
  # 🍖 Biological Simulation: Hunger, Fatigue, Alertness
  # 🧠 Predatory Pattern Matching: Markov-style focus prediction

  def self.tick(raid_state, elapsed_hours, user_sessions)
    # 🍖 Metabolism: Monster grows hungry and tired over time
    hp_ratio = raid_state[:current_hp].to_f / raid_state[:max_hp]
    
    # Hunger: Increases based on player's procrastination (chaos_level)
    # If the user isn't finishing tasks, the monster "feeds" on the entropy, but stays "hungry" for focus.
    hunger_gain = 5.0 + (elapsed_hours * 10.0)
    raid_state[:hunger] = [(raid_state[:hunger] || 0.0) + hunger_gain, 100.0].min
    
    # Fatigue: Increases during combat sessions, decreases over time
    fatigue_decay = elapsed_hours * 5.0
    raid_state[:fatigue] = [(raid_state[:fatigue] || 0.0) - fatigue_decay, 0.0].max
    
    # 🧠 Predatory Prediction (Markov Chain)
    # Analyze user_sessions (past 24h) to identify "danger zones" for the user.
    # If the current hour is a typical "failure" hour, alertness increases.
    current_hour = Time.now.hour
    alertness = calculate_alertness(current_hour, user_sessions)
    raid_state[:alertness] = alertness
    
    raid_state
  end

  def self.calculate_alertness(hour, sessions)
    # Simple Markov: P(Focus | Hour)
    # Count sessions in this hour vs total days
    focus_history = sessions.select { |s| DateTime.parse(s[:started_at]).hour == hour }
    probability = focus_history.count / 7.0 # Based on weekly data
    
    # Alertness is high when the user is EXPECTED to focus but doesn't.
    (1.0 - probability).clamp(0.1, 1.0)
  end

  def self.decide_action(raid_state, entropy)
    # Inherit base patterns
    base_action = ActionPatterns.select_action(raid_state[:current_phase], entropy)
    
    # 🍖 Biological Overrides
    if raid_state[:hunger] > 80.0
      # 🍖 Starving: Mandatory Chaos Breath (Preying on entropy)
      return ActionPatterns::ACTIONS[:chaos_breath].merge(name: "飢餓の【カオス・ブレス】")
    elsif raid_state[:alertness] > 0.8
      # 👁️ Predatory: Data Void (Attacking the focus sync)
      return ActionPatterns::ACTIONS[:data_void].merge(name: "捕食者の証【データの虚無】")
    end
    
    base_action
  end
end
