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
        user.update!(coins: user.coins - UPGRADE_COST_COINS)
        user.materials["moko_stone"] -= UPGRADE_COST_STONES
        user.save!
        
        moko.update!(rarity: moko.rarity + 1)
      end
      
      msg = MokoGrammarService.mokofize("#{moko_item_id}がランクアップしましたもこ！ピカピカだもこ！✨")
      { success: true, message: msg }
    else
      { success: false, error: "素材が足りないもこ..." }
    end
  end
end
