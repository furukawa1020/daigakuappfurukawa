class CombatEngineService
  # Phase 48: Neural Resonance Multipliers (Replaces Sharpness)
  RESONANCE_MULTIPLIERS = {
    80..100 => 1.50, # Harmonized (Gold)
    60..79  => 1.25, # High Sync (Cyan)
    40..59  => 1.05, # Stable (Green)
    20..39  => 0.80, # Decaying (Yellow)
    0..19   => 0.40  # Muted (Red)
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
      return { damage: 0, hp: user.hp, stunned: true, message: '気絶状態もこ...集中力を奪われているもこ！' }
    end

    # 1. Bio-Sync Modifiers (Phase 48 Core)
    order = user.order_level # 0.0 - 1.0
    chaos = user.chaos_level # 0.0 - 1.0
    
    order_mult = 1.0 + (order * 0.5) # Up to 50% dmg bonus for high streak
    chaos_mult = 1.0 + (chaos * 0.5) # Up to 50% monster counter bonus for too many tasks

    # 2. Neural Resonance (斬れ味に代わる同調率)
    res_value = user.neural_resonance
    resonance_mult = RESONANCE_MULTIPLIERS.find { |range, _| range.include?(res_value) }&.last || 1.0

    # 3. Target Hitzone
    hitzones = MONSTER_HITZONES[raid.title.parameterize.underscore] || { head: 50, body: 50 }
    target = decide_hitzone(user, hitzones)
    hzv = hitzones[target] || 50
    
    # 4. Neural Bounce Check (同調拒絶判定)
    is_bounce = (resonance_mult * hzv) < 25
    bounce_mult = is_bounce ? 0.3 : 1.0
    
    # 5. Monster Counter-Attack (のカオス倍率)
    monster_state = MonsterAIEngine.get_state_modifiers(raid)
    counter_damage = (monster_state[:damage_mult] * 12 * chaos_mult).to_i # Procrastination hurts!
    
    # Status Chance: Affected by Chaos
    if rand < (chaos * 0.3)
      effect = 'poisoned'
      current_status[effect] = true
    end

    # 6. Final Damage Calculation
    # Affinity is now purely linked to Order (Streak)
    affinity = (order * 50).to_i + 10 # Base 10% + up to 50%
    is_critical = rand(100) < affinity
    crit_mult = is_critical ? 1.35 : 1.0 # Slightly stronger crit for Master Rank

    final_damage = (base_damage * resonance_mult * (hzv / 100.0) * bounce_mult * order_mult * crit_mult).to_i
    final_damage = 0 if user.stamina <= 0 
    
    # 7. Part Durability & Flinch
    durabilities = raid.part_durabilities || {}
    is_flinched = false
    is_broken = false
    
    if durabilities[target]
      durabilities[target] -= final_damage
      if durabilities[target] <= 0
        is_flinched = true
        is_broken = true if durabilities[target] < -1000
        durabilities[target] = 3000 # Higher resistance in Master Rank
      end
    end
    raid.update!(part_durabilities: durabilities)

    # 8. Impact & User State Resolve
    new_hp = [user.hp - counter_damage, 0].max
    
    user.update!(
      hp: new_hp,
      stamina: [user.stamina - 15, 0].max, # Higher drain
      status_effects: current_status
    )
    
    {
      damage: final_damage,
      is_bounce: is_bounce,
      is_critical: is_critical,
      target_part: target,
      resonance_level: res_value,
      hp: new_hp,
      stamina: user.stamina,
      status_effects: current_status,
      fainted: new_hp <= 0,
      flinched: is_flinched,
      hit_stop: is_critical ? 200 : 80,
      shake: 2.0 + (chaos * 6.0), # Chaos increases screen shake intensity
      chaos_level: chaos,
      order_level: order,
      moko_message: generate_moko_message(is_critical, is_bounce, is_flinched, new_hp, chaos)
    }
  end

  private

  def self.generate_moko_message(crit, bounce, flinch, hp, chaos)
    if hp <= 0
      "わあああ！！しっかりするもこ！もう限界だもこ！！😭"
    elsif bounce
      "カキン！同調が合ってないもこ！今の自分を見つめ直すもこ...！💢"
    elsif crit
      "すごいもこ！！その調子でもっと自分を追い込むもこ！✨🔥"
    elsif flinch
      "チャンスだもこ！一気に畳み掛けるもこ！！🐾⚔️"
    elsif chaos > 0.8
      "危ないもこ！タスクが溜まりすぎてモンスターが狂暴になってるもこ...！😱"
    else
      "いい感じだもこ。一歩ずつ、確実に進むもこ。🐾"
    end
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
