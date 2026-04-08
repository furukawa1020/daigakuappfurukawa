# ruby_native/core/action_patterns.rb
class ActionPatterns
  ACTIONS = {
    normal_attack: { id: 'normal_attack', name: '薙ぎ払い', base_damage: 15, type: :physical },
    data_void: { id: 'data_void', name: 'データの虚無', base_damage: 5, type: :mental },
    chaos_breath: { id: 'chaos_breath', name: 'カオス・ブレス', base_damage: 30, type: :chaos },
    entropy_surge: { id: 'entropy_surge', name: 'エントロピー暴走', base_damage: 50, type: :ultimate }
  }

  def self.select_action(raid_phase, global_entropy)
    if global_entropy > 0.8 && raid_phase >= 2
      rand(100) < 20 ? ACTIONS[:entropy_surge] : ACTIONS[:chaos_breath]
    elsif global_entropy > 0.5
      rand(100) < 40 ? ACTIONS[:chaos_breath] : ACTIONS[:data_void]
    elsif raid_phase == 3
      [ACTIONS[:chaos_breath], ACTIONS[:data_void], ACTIONS[:normal_attack]].sample
    else
      rand(100) < 30 ? ACTIONS[:data_void] : ACTIONS[:normal_attack]
    end
  end
end
