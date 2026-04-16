class FocusSynergyService
  # Analyzes current Moko items and Active Goal types to provide buffs
  def self.calculate_buffs(user)
    buffs = []
    active_moko_ids = user.moko_items.pluck(:item_id)
    
    # 1. Study Synergy: (Intellectual personality + Studying goal)
    studying_goals = user.goal_nodes.where(completed: false).where("title LIKE ?", "%勉強%").or(user.goal_nodes.where("title LIKE ?", "%学習%"))
    if studying_goals.any? && active_moko_ids.include?("intellectual")
      buffs << { type: "xp_boost", value: 1.2, name: "集中学習相乗効果" }
    end
    
    # 2. Rarity Synergy: (Rare items + long sessions)
    rare_count = user.moko_items.where("rarity >= 3").count
    if rare_count >= 2
      buffs << { type: "coin_boost", value: 1.5, name: "レアもこ財宝" }
    end
    
    # 3. World Weather Synergy
    world = MokoWorldService.current_status
    if world[:weather] == "focus_storm"
      buffs << { type: "xp_boost", value: 1.5, name: "嵐の集中ボーナス" }
    end
    
    buffs
  end
end
