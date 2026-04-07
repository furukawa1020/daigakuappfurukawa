class ActionPatternService
  # Phase 50: Sophisticated Monster Behaviors
  ACTIONS = {
    normal_attack: {
      id: 'normal_attack',
      name: '薙ぎ払い',
      base_damage: 15,
      type: :physical,
      description: '物理的なダメージを与えてくるもこ。'
    },
    data_void: {
      id: 'data_void',
      name: 'データの虚無',
      base_damage: 5,
      type: :mental,
      description: '神経同調率（Neural Resonance）を強制的に低下させるもこ！'
    },
    chaos_breath: {
      id: 'chaos_breath',
      name: 'カオス・ブレス',
      base_damage: 30,
      type: :chaos,
      description: '未完了タスクが多い者ほど大ダメージを受ける即死級のブレスもこ！'
    },
    entropy_surge: {
      id: 'entropy_surge',
      name: 'エントロピー暴走',
      base_damage: 50,
      type: :ultimate,
      description: '世界中のサボりが集結した究極の一撃！タンクの軽減が必要もこ！'
    }
  }

  def self.select_action(raid, global_entropy)
    phase = raid.current_phase || 1
    
    # Probabilities based on phase and global entropy
    if global_entropy > 0.8 && phase >= 2
      # Very High Entropy = Ultimate attack possible
      rand(100) < 20 ? ACTIONS[:entropy_surge] : ACTIONS[:chaos_breath]
    elsif global_entropy > 0.5
      # Medium Entropy = Chaos Breath becomes common
      rand(100) < 40 ? ACTIONS[:chaos_breath] : ACTIONS[:data_void]
    elsif phase == 3
      # Final Phase is always intense
      action_pool = [ACTIONS[:chaos_breath], ACTIONS[:data_void], ACTIONS[:normal_attack]]
      action_pool.sample
    else
      # Normal Phase 1/2 with low entropy
      rand(100) < 30 ? ACTIONS[:data_void] : ACTIONS[:normal_attack]
    end
  end
end
