# ruby_native/core/combat_engine.rb
require_relative 'action_patterns'

class CombatEngine
  RESONANCE_MULTIPLIERS = {
    80..100 => 1.50,
    60..79  => 1.25,
    40..59  => 1.05,
    20..39  => 0.80,
    0..19   => 0.40
  }

  def self.calculate_damage(user_state, raid_state, base_damage, global_entropy)
    current_status = user_state[:status_effects] || {}
    return { damage: 0, hp: 0, fainted: true } if (user_state[:hp] || 0) <= 0
    
    # ⚖️ Modifiers
    order = user_state[:order_level] || 0.0
    chaos = user_state[:chaos_level] || 0.0
    res_value = user_state[:neural_resonance] || 50
    resonance_mult = RESONANCE_MULTIPLIERS.find { |range, _| range.include?(res_value) }&.last || 1.0
    
    # 🎯 Targeting
    hzv = 50 # Default hitzone
    affinity = (order * 50).to_i + 10
    is_critical = rand(100) < affinity
    crit_mult = is_critical ? 1.35 : 1.0
    
    final_damage = (base_damage * resonance_mult * (hzv / 100.0) * crit_mult * (1.0 + order * 0.5)).to_i
    final_damage = 0 if (user_state[:stamina] || 0) <= 0

    # 🐉 Monster AI Evaluation
    monster_action = ActionPatterns.select_action(raid_state[:current_phase], global_entropy)
    base_counter = monster_action[:base_damage]
    
    # 🛡️ Role-Based Synergy
    case user_state[:role]
    when 'tank'
      counter_damage = (base_counter * 0.5 * (1.0 + chaos * 0.5)).to_i
      hit_msg = "【Tank】#{monster_action[:name]} を防御！"
    when 'support'
      if rand < 0.3
        counter_damage = 0
        hit_msg = "【Support】#{monster_action[:name]} を回避！"
      else
        counter_damage = (base_counter * 1.5 * (1.0 + chaos * 0.5)).to_i
        hit_msg = "【Support】直撃！#{monster_action[:name]}"
      end
    else
      counter_damage = (base_counter * (1.0 + chaos * 0.5)).to_i
      hit_msg = "【DPS】#{monster_action[:name]} を受けた！"
    end

    # 🌪️ Status Effects
    if rand < (chaos * 0.3)
      current_status['poisoned'] = true
    end

    {
      damage: final_damage,
      is_critical: is_critical,
      hp: [user_state[:hp] - counter_damage, 0].max,
      stamina: [user_state[:stamina] - 15, 0].max,
      status_effects: current_status,
      monster_action: monster_action[:name],
      combat_message: hit_msg,
      shake: 2.0 + (chaos * 6.0),
      hit_stop: is_critical ? 200 : 80
    }
  end
end
