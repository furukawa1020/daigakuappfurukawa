class MokoAlchemyService
  # Cost to upgrade: 50 coins + 5 moko_stones
  UPGRADE_COST_COINS = 50
  UPGRADE_COST_STONES = 5

  def self.craft_upgrade!(user, moko_item_id)
    moko = user.moko_items.find_by(item_id: moko_item_id)
    return { success: false, error: "Not found" } unless moko
    return { success: false, error: "Max rarity reached" } if moko.rarity.to_i >= 5

    stones = (user.materials["moko_stone"] || 0).to_i
    if user.coins.to_i >= UPGRADE_COST_COINS && stones >= UPGRADE_COST_STONES
      ActiveRecord::Base.transaction do
        user.update!(coins: user.coins.to_i - UPGRADE_COST_COINS)
        user.materials["moko_stone"] = user.materials["moko_stone"].to_i - UPGRADE_COST_STONES
        user.save!
        
        moko.update!(rarity: moko.rarity.to_i + 1)
      end
      
      msg = MokoGrammarService.mokofize("#{moko_item_id}がランクアップしましたもこ！ピカピカだもこ！✨")
      { success: true, message: msg }
    else
      { success: false, error: "素材が足りないもこ..." }
    end
  def self.craft_holy_water!(user)
    stones = (user.materials["moko_stone"] || 0).to_i
    cost_coins = 100
    cost_stones = 10

    if user.coins.to_i >= cost_coins && stones >= cost_stones
      ActiveRecord::Base.transaction do
        user.update!(coins: user.coins.to_i - cost_coins)
        user.materials["moko_stone"] = user.materials["moko_stone"].to_i - cost_stones
        user.save!
        
        # Clear the skill on the active raid
        raid = GlobalRaid.active.first
        raid&.clear_skill!
      end
      
      { success: true, message: MokoGrammarService.mokofize("聖水を作って呪いを浄化したもこ！キリッとしたもこ！✨") }
    else
      { success: false, error: "素材が足りないもこ... 聖水には力が必要だもこ。" }
    end
  end
end
