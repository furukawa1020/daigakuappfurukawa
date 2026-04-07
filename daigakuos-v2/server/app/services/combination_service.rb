class CombinationService
  RECIPES = {
    'potion' => { 
      name: '回復薬', 
      materials: { 'herb' => 1, 'blue_mushroom' => 1 },
      desc: '体力を30回復するもこ！'
    },
    'mega_potion' => { 
      name: '回復薬グレート', 
      materials: { 'potion' => 1, 'honey' => 1 },
      desc: '体力を100回復する大幅回復薬だもこ！'
    },
    'antidote' => { 
      name: '解毒薬', 
      materials: { 'antidote_herb' => 1, 'blue_mushroom' => 1 },
      desc: '毒状態を解除するもこ！'
    },
    'energy_drink' => { 
      name: 'エナジードリンク', 
      materials: { 'honey' => 1, 'nitroshroom' => 1 },
      desc: 'スタミナを全回復し、疲労を回復するもこ！'
    }
  }

  def self.combine!(user, item_id)
    recipe = RECIPES[item_id]
    return { success: false, error: 'レシピが見つからないもこ...' } unless recipe
    
    inventory = user.inventory || {}
    materials = user.materials || {}
    
    # 1. Check ingredients (Combined check from materials and inventory)
    recipe[:materials].each do |mat, count|
      total_count = (inventory[mat] || 0) + (materials[mat] || 0)
      if total_count < count
        return { success: false, error: "素材【#{mat}】が足りないもこ！" }
      end
    end
    
    # 2. Consume ingredients
    recipe[:materials].each do |mat, count|
      if (inventory[mat] || 0) >= count
        inventory[mat] -= count
      else
        remaining = count - (inventory[mat] || 0)
        inventory[mat] = 0
        materials[mat] -= remaining
      end
    end
    
    # 3. Add result to inventory
    inventory[item_id] = (inventory[item_id] || 0) + 1
    
    # 4. Save
    user.update!(inventory: inventory, materials: materials)
    
    { success: true, item_name: recipe[:name], message: "『#{recipe[:name]}』の調合に成功したもこ！✨" }
  end
end
