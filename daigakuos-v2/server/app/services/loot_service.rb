class LootService
  LEGENDARY_ITEMS = {
    'dragon_heart' => { name: "竜の心臓", desc: "集中中のダメージボーナス +10%", buff: { raid_damage: 0.1 } },
    'mist_cape' => { name: "影のケープ", desc: "ボスのデバフによる減衰を 20% 軽減", buff: { debuff_resistance: 0.2 } },
    'ancient_crystal' => { name: "古の水晶", desc: "集中セッション獲得XP +15%", buff: { xp_bonus: 0.15 } },
    'hero_medal' => { name: "英雄の勲章", desc: "全ステータス +5% (Raid報酬)", buff: { all_stats: 0.05 } }
  }

  def self.distribute_boss_loot!(user, raid, contribution_rank)
    archive = user.boss_archive || {}
    boss_key = raid.title.parameterize.underscore
    
    # 1. Boss Part (Archive) - Guaranteed for participation
    archive[boss_key] ||= { parts: [], kills: 0 }
    archive[boss_key][:kills] += 1
    
    # Parts drop logic (Collect 3 parts to complete a boss trophy)
    available_parts = ['core', 'shell', 'essence']
    new_part = available_parts.sample
    archive[boss_key][:parts] << new_part unless archive[boss_key][:parts].include?(new_part)
    
    # 2. Legendary Loot - Low probability, higher for top ranks
    drop_chance = case contribution_rank
                  when 0 then 0.20 # Top 1: 20%
                  when 1..2 then 0.10 # Top 3: 10%
                  else 0.02 # Others: 2%
                  end
    
    legendary_drop = nil
    if rand < drop_chance
      legendary_drop = LEGENDARY_ITEMS.keys.sample
      user.add_material!(legendary_drop, 1) # Reuse material system for simple storage
      
      # Add to passive buffs
      passives = user.passive_buffs || {}
      item_info = LEGENDARY_ITEMS[legendary_drop]
      
      item_info[:buff].each do |key, value|
        passives[key] = (passives[key] || 0) + value
      end
      user.update!(passive_buffs: passives)
    end
    
    user.update!(boss_archive: archive)
    
    {
      new_part: new_part,
      legendary_drop: legendary_drop,
      total_parts: archive[boss_key][:parts].length
    }
  end

  def self.get_passive_multiplier(user, buff_key)
    passives = user.passive_buffs || {}
    1.0 + (passives[buff_key.to_s] || 0.0)
  end
end
