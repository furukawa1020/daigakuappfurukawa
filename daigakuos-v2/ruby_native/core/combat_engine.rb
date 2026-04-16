# ruby_native/core/combat_engine.rb
require_relative 'action_patterns'

class CombatEngine
  # 🧬 Biological Metabolic Multipliers
  METABOLIC_MULTIPLIERS = {
    80..100 => 1.50,
    60..79  => 1.25,
    40..59  => 1.05,
    20..39  => 0.80,
    0..19   => 0.40
  }

  def self.calculate_damage(user_state, raid_state, base_damage, toxin_load)
    current_status = user_state[:status_effects] || {}
    return { damage: 0, hp: 0, fainted: true } if (user_state[:hp] || 0) <= 0
    
    # ⚖️ Modifiers
    order = user_state[:order_level] || 0.0
    chaos = user_state[:chaos_level] || 0.0
    toxin_mult = 1.0 - ((user_state[:toxins] || 0.0) / 200.0)
    oxygen_mult = 1.0 + ((user_state[:oxygen] || 0.0) / 200.0)
    
    sync_value = user_state[:metabolic_sync] || 50
    metabolic_mult = METABOLIC_MULTIPLIERS.find { |range, _| range.include?(sync_value) }&.last || 1.0
    
    # 🎯 Targeting
    hzv = 50 
    affinity = (order * 50).to_i + 10
    is_critical = rand(100) < affinity
    crit_mult = is_critical ? 1.35 : 1.0
    
    # 💥 Final Damage: Now influenced by the Biological Ecosystem!
    final_damage = (base_damage * metabolic_mult * (hzv / 100.0) * crit_mult * (1.0 + order * 0.5) * oxygen_mult).to_i
    final_damage = 0 if (user_state[:stamina] || 0) <= 0

    # 🐉 Monster AI Evaluation (Biological Brain)
    monster_action = MonsterBrain.decide_action(raid_state, toxin_load)
    mode_info = MonsterBrain::BEHAVIOR_MODES[raid_state[:behavior_mode] || :grazing]
    
    # Base Counter influenced by behavioral multi
    base_counter = monster_action[:base_damage] * (monster_action[:damage_mult] || 1.0)
    
    # 🛡️ Role-Based Synergy (Affected by Toxins & Behavior!)
    case user_state[:role]
    when 'tank'
      counter_damage = (base_counter * 0.5 * (1.0 + chaos * 0.5) * (2.0 - toxin_mult)).to_i
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
      # Enraged monsters hit much harder on DPS
      mult = (raid_state[:behavior_mode] == :enraged) ? 1.4 : 1.0
      counter_damage = (base_counter * (1.0 + chaos * 0.5) * mult).to_i
      hit_msg = "【#{user_state[:role].upcase}】#{monster_action[:name]} を受けた！"
    end

    # 🌪️ Status Effects (Probability increased in Starving/Enraged modes)
    status_threshold = 0.3 + (raid_state[:behavior_mode] == :starving ? 0.3 : 0.0)
    if rand < (chaos * status_threshold)
      current_status['poisoned'] = true
    end

    {
      damage: final_damage,
      is_critical: is_critical,
      hp: [user_state[:hp] - counter_damage, 0].max,
      stamina: [user_state[:stamina] - 15, 0].max,
      status_effects: current_status,
      monster_action: monster_action[:name],
      behavior_mode: raid_state[:behavior_mode], # Send mode back to Flutter
      combat_message: hit_msg,
      shake: 2.0 + (chaos * 6.0) + (raid_state[:behavior_mode] == :enraged ? 4.0 : 0.0),
      hit_stop: is_critical ? 200 : 80
    }
  end
end
