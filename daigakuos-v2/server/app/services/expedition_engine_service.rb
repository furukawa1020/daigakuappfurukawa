class ExpeditionEngineService
  # Processes a focus session to progress the active quest & damage monsters
  def self.process_session!(user, session)
    expedition = user.moko_expeditions.active.first
    return nil unless expedition

    # 1. Base Damage/Progress = Duration in minutes
    base_progress = session.duration.to_f
    
    # 2. Synergy Multiplier
    active_buffs = FocusSynergyService.calculate_buffs(user)
    # E.g. {"xp_boost"=>1.2, "coin_boost"=>1.5}
    multiplier = 1.0
    active_buffs.each do |buff|
      multiplier *= buff[:value] if buff[:type] == "xp_boost"
    end

    # 3. Final Damage Calculation
    damage = base_progress * multiplier
    
    new_progress = expedition.progress + damage
    new_hp = expedition.monster_hp - damage.round

    expedition.progress = new_progress
    expedition.monster_hp = [new_hp, 0].max

    if expedition.monster_hp <= 0 || expedition.progress >= expedition.required_focus_minutes
      expedition.complete!
      grant_rewards!(user, expedition)
      return { status: "completed", damage: damage.round, expedition: expedition }
    else
      expedition.save!
      return { status: "active", damage: damage.round, expedition: expedition }
    end
  end

  def self.start_quest!(user, quest_type)
    return { success: false, error: "Already on a quest" } if user.moko_expeditions.active.exists?

    case quest_type
    when "social_media_monster"
      exp = user.moko_expeditions.create!(
        name: "SNSの誘惑魔人討伐",
        difficulty: 3,
        required_focus_minutes: 60,
        monster_hp: 60,
        rewards: { "star_dust" => 3, "moko_stone" => 5 }
      )
    when "sleepiness_dragon"
      exp = user.moko_expeditions.create!(
        name: "睡魔竜討伐",
        difficulty: 5,
        required_focus_minutes: 120,
        monster_hp: 120,
        rewards: { "star_dust" => 5, "moko_special_egg" => 1 }
      )
    else
      return { success: false, error: "Unknown quest type" }
    end

    { success: true, expedition: exp }
  end

  private

  def self.grant_rewards!(user, expedition)
    ActiveRecord::Base.transaction do
      expedition.rewards.each do |item, amount|
        user.add_material!(item, amount)
      end
      # Give some standard coin reward as well based on difficulty
      user.update!(coins: user.coins + (expedition.difficulty * 20))
    end
    
    # Notify User via ActionCable
    msg = MokoGrammarService.mokofize("#{expedition.name}を討伐したもこ！報酬を持ち帰ったもこよ！🎉")
    ActionCable.server.broadcast("activity_feed", {
      type: "expedition_completed",
      message: msg,
      rewards: expedition.rewards
    })
  end
end
