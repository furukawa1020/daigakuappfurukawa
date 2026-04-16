class BlacksmithService
  RECIPES = {
    'wyvern_blade' => { 
      name: 'ワイバーン・ブレイド', 
      materials: { 'wyvern_scale' => 10, 'wyvern_marrow' => 1 },
      buff: { raid_damage: 0.15 },
      desc: '飛竜の力を宿した大剣。レイドダメージが15%上昇するもこ！'
    },
    'behemoth_mail' => { 
      name: 'ベヒーモス・メイル', 
      materials: { 'behemoth_horn' => 5, 'shadow_claw' => 3 },
      buff: { debuff_resistance: 0.20 },
      desc: '深淵の獣の殻から作った鎧。デバフを20%軽減するもこ！'
    },
    'kirin_horn_blade' => { 
      name: '麒麟の角刀', 
      materials: { 'kirin_azure_horn' => 1, 'kirin_hoof' => 10 },
      buff: { xp_bonus: 0.30 },
      desc: '雷光をまとう神々しい刀。獲得XPが30%も増えるもこ！'
    }
  }

  def self.craft!(user, item_id)
    recipe = RECIPES[item_id]
    return { success: false, error: 'レシピが見つからないもこ...' } unless recipe
    
    inventory = user.inventory || {}
    
    # 1. Check materials
    recipe[:materials].each do |mat, count|
      if (inventory[mat] || 0) < count
        return { success: false, error: "素材【#{mat}】が足りないもこ！ あと #{count - (inventory[mat] || 0)} 個必要だもこ。" }
      end
    end
    
    # 2. Consume materials
    recipe[:materials].each do |mat, count|
      inventory[mat] -= count
    end
    
    # 3. Add to User's Passive Buffs
    passives = user.passive_buffs || {}
    recipe[:buff].each do |key, value|
      passives[key] = (passives[key] || 0) + value
    end
    
    # 4. Save
    user.update!(inventory: inventory, passive_buffs: passives)
    
    # 5. Broadcast to chat
    ActionCable.server.broadcast("chat_channel", {
      username: "SYSTEM",
      content: "🔨 【#{user.username}】が伝説の装備『#{recipe[:name]}』をクラフトしたもこ！✨",
      timestamp: Time.current.strftime("%H:%M")
    })
    
    { success: true, item_name: recipe[:name], message: "『#{recipe[:name]}』を鍛え上げたもこ！大切に使うもこ！" }
  end
end
