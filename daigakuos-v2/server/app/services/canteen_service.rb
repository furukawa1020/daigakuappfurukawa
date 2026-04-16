class CanteenService
  MEALS = {
    'moko_stew' => { 
      name: 'モコ特製煮込み', 
      buffs: { hp_boost: 50, stamina_boost: 50 },
      desc: '体力とスタミナの最大値が大幅にアップするもこ！'
    },
    'hunter_steak' => { 
      name: 'ハンター・ステーキ', 
      buffs: { atk_boost: 0.15 },
      desc: '攻撃力が15%アップするスタミナ料理だもこ！'
    },
    'veggie_platter' => { 
      name: '山盛り野菜盛り合わせ', 
      buffs: { def_boost: 0.20 },
      desc: '防御力が20%アップし、状態異常に強くなるもこ！'
    }
  }

  def self.eat!(user, meal_id)
    meal = MEALS[meal_id]
    return { success: false, error: 'メニューにないもこ...' } unless meal
    
    # Apply buffs (stored in User)
    user.meal_buffs = meal[:buffs]
    
    # In MH, meals often also restore current HP/ST
    user.hp = [user.hp + (meal[:buffs][:hp_boost] || 0), user.max_hp + (meal[:buffs][:hp_boost] || 0)].min
    user.stamina = [user.stamina + (meal[:buffs][:stamina_boost] || 0), user.max_stamina + (meal[:buffs][:stamina_boost] || 0)].min
    
    user.save!
    
    ActionCable.server.broadcast("chat_channel", {
      username: "SYSTEM",
      content: "🍖✨ 【#{user.username}】が食卓を囲んで『#{meal[:name]}』を楽しんだもこ！体に力がみなぎってきたもこ！",
      timestamp: Time.current.strftime("%H:%M")
    })
    
    { success: true, meal_name: meal[:name], message: "『#{meal[:name]}』を完食したもこ！ごちそうさまだもこ！✨" }
  end

  def self.clear_buffs!(user)
    user.update!(meal_buffs: {})
  end
end
