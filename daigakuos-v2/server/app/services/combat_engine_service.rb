class CombatEngineService
  SHARPNESS_MULTIPLIERS = {
    'white' => 1.32,
    'blue' => 1.20,
    'green' => 1.05,
    'yellow' => 1.00,
    'orange' => 0.75,
    'red' => 0.50
  }

  # HZV (Hitzone Values / 肉質) for each monster
  MONSTER_HITZONES = {
    'moko_wyvern' => { head: 80, body: 40, tail: 60, feet: 25 },
    'shadow_behemoth' => { horn: 90, body: 30, tail: 50, leg: 20 },
    'flame_kirin' => { horn: 100, body: 15, tail: 40, leg: 10 }
  }

  def self.calculate_damage(user, raid, base_damage)
    # 1. Sharpness Multiplier
    color = user.sharpness_color
    sharpness_mult = SHARPNESS_MULTIPLIERS[color] || 1.0
    
    # 2. Target Hitzone (Randomly decide focus but weighted towards head/body)
    hitzones = MONSTER_HITZONES[raid.title.parameterize.underscore] || { head: 50, body: 50 }
    target = decide_hitzone(user, hitzones)
    hzv = hitzones[target] || 50
    
    # 3. Bounce Check (弾かれ判定)
    # Formula: Multiplier * HZV < 25
    is_bounce = (sharpness_mult * hzv) < 25
    bounce_mult = is_bounce ? 0.5 : 1.0
    
    # 4. Sharpness Loss
    loss_amount = is_bounce ? 2 : 1
    user.update!(current_sharpness: [user.current_sharpness - loss_amount, 0].max)
    
    # 5. Final Calculation
    # Damage = (Base * Sharpness * HZV / 100) * Bounce Penalty
    final_damage = (base_damage * sharpness_mult * (hzv / 100.0) * bounce_mult).to_i
    
    {
      damage: final_damage,
      is_bounce: is_bounce,
      target_part: target,
      sharpness_color: color,
      hzv: hzv
    }
  end

  private

  def self.decide_hitzone(user, hitzones)
    # High quality sessions target head more often
    # For now, let's keep it simple: 30% Head, 40% Body, 20% Tail, 10% Other
    r = rand(100)
    if r < 30 then :head
    elsif r < 70 then :body
    elsif r < 90 then :tail
    else hitzones.keys.sample
    end
  end
end
