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
    # 0. Faint & Stun Check
    current_status = user.status_effects || {}
    return { damage: 0, hp: 0, fainted: true } if user.hp <= 0
    
    if current_status['stunned']
      current_status.delete('stunned')
      user.update!(status_effects: current_status)
      return { damage: 0, hp: user.hp, stunned: true, message: '気絶して動けないもこ！💫' }
    end

    # 1. Apply Meal Buffs
    meal = user.meal_buffs || {}
    atk_mult = 1.0 + (meal['atk_boost'] || 0)
    def_mult = 1.0 - (meal['def_boost'] || 0)

    # 2. Master Rank Logic: Affinity (会心判定)
    affinity = 25 # Base Master Rank Affinity
    is_critical = rand(100) < affinity
    crit_mult = is_critical ? 1.25 : 1.0

    # 3. Sharpness Multiplier
    color = user.sharpness_color
    sharpness_mult = SHARPNESS_MULTIPLIERS[color] || 1.0
    
    # 4. Target Hitzone
    hitzones = MONSTER_HITZONES[raid.title.parameterize.underscore] || { head: 50, body: 50 }
    target = decide_hitzone(user, hitzones)
    hzv = hitzones[target] || 50
    
    # 5. Bounce Check
    is_bounce = (sharpness_mult * hzv) < 25
    bounce_mult = is_bounce ? 0.5 : 1.0
    
    # 6. Sharpness & Stamina Loss
    sharpness_loss = is_bounce ? 2 : 1
    stamina_loss = 10
    
    # 7. Monster Counter-Attack
    monster_state = MonsterAIEngine.get_state_modifiers(raid)
    counter_damage = (monster_state[:damage_mult] * 10 * def_mult).to_i
    
    # Status Chance
    if rand < (monster_state[:damage_mult] * 0.1)
      effect = raid.title.include?('Wyvern') ? 'poisoned' : 'stunned'
      current_status[effect] = true
    end

    # 8. Poison Damage
    if current_status['poisoned']
      counter_damage += 5
    end
    
    # 9. Final Calculation
    final_damage = (base_damage * sharpness_mult * (hzv / 100.0) * bounce_mult * atk_mult * crit_mult).to_i
    final_damage = 0 if user.stamina <= 0 
    
    # 10. Part Durability & Flinch Logic (部位耐久値)
    durabilities = raid.part_durabilities || {}
    is_flinched = false
    is_broken = false
    
    if durabilities[target]
      durabilities[target] -= final_damage
      if durabilities[target] <= 0
        is_flinched = true
        is_broken = true if durabilities[target] < -500 # Major break
        durabilities[target] = 2000 # Reset durability for next flinch
      end
    end
    raid.update!(part_durabilities: durabilities)

    # 11. Kinetic Feedback Calculation (インパクトデータ)
    hit_stop = is_critical ? 150 : (final_damage > 100 ? 100 : 50) # ms
    shake = is_critical ? 8.0 : (is_bounce ? 5.0 : 2.0) # units

    # Resolve User States
    new_hp = [user.hp - counter_damage, 0].max
    new_stamina = [user.stamina - stamina_loss, 0].max
    
    user.update!(
      current_sharpness: [user.current_sharpness - sharpness_loss, 0].max,
      hp: new_hp,
      stamina: new_stamina,
      status_effects: current_status
    )
    
    {
      damage: final_damage,
      is_bounce: is_bounce,
      is_critical: is_critical,
      target_part: target,
      sharpness_color: color,
      hp: new_hp,
      stamina: new_stamina,
      status_effects: current_status,
      fainted: new_hp <= 0,
      fatigued: new_stamina <= 0,
      flinched: is_flinched,
      broken: is_broken,
      hit_stop: hit_stop,
      shake: shake
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
