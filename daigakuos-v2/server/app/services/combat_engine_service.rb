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
    # 0. Faint & Stun Check (状態異常判定)
    current_status = user.status_effects || {}
    return { damage: 0, hp: 0, fainted: true } if user.hp <= 0
    
    if current_status['stunned']
      current_status.delete('stunned')
      user.update!(status_effects: current_status)
      return { damage: 0, hp: user.hp, stunned: true, message: '気絶して動けないもこ！💫' }
    end

    # 1. Apply Meal Buffs (食事効果)
    meal = user.meal_buffs || {}
    atk_mult = 1.0 + (meal['atk_boost'] || 0)
    def_mult = 1.0 - (meal['def_boost'] || 0)

    # 2. Sharpness Multiplier
    color = user.sharpness_color
    sharpness_mult = SHARPNESS_MULTIPLIERS[color] || 1.0
    
    # 3. Target Hitzone
    hitzones = MONSTER_HITZONES[raid.title.parameterize.underscore] || { head: 50, body: 50 }
    target = decide_hitzone(user, hitzones)
    hzv = hitzones[target] || 50
    
    # 4. Bounce Check (弾かれ判定)
    is_bounce = (sharpness_mult * hzv) < 25
    bounce_mult = is_bounce ? 0.5 : 1.0
    
    # 5. Sharpness & Stamina Loss
    sharpness_loss = is_bounce ? 2 : 1
    stamina_loss = 10
    
    # 6. Monster Counter-Attack & Status Infliction
    monster_state = MonsterAIEngine.get_state_modifiers(raid)
    counter_damage = (monster_state[:damage_mult] * 10 * def_mult).to_i # Apply Defense Buff
    
    # Status Chance
    if rand < (monster_state[:damage_mult] * 0.1) # 10% base chance, higher if enraged
      effect = raid.title.include?('Wyvern') ? 'poisoned' : 'stunned'
      current_status[effect] = true
    end

    # 7. Poison Damage (毒の継続ダメージ)
    if current_status['poisoned']
      counter_damage += 5
    end
    
    # Resolve User States
    new_sharpness = [user.current_sharpness - sharpness_loss, 0].max
    new_hp = [user.hp - counter_damage, 0].max
    new_stamina = [user.stamina - stamina_loss, 0].max
    
    user.update!(
      current_sharpness: new_sharpness,
      hp: new_hp,
      stamina: new_stamina,
      status_effects: current_status
    )
    
    # 8. Final Calculation
    final_damage = (base_damage * sharpness_mult * (hzv / 100.0) * bounce_mult * atk_mult).to_i
    final_damage = 0 if new_stamina <= 0 
    
    {
      damage: final_damage,
      is_bounce: is_bounce,
      target_part: target,
      sharpness_color: color,
      hp: new_hp,
      stamina: new_stamina,
      status_effects: current_status,
      fainted: new_hp <= 0,
      fatigued: new_stamina <= 0
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
