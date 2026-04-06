class GlobalRaid < ApplicationRecord
  serialize :participants_data, coder: JSON
  
  validates :title, presence: true
  validates :max_hp, numericality: { greater_than: 0 }
  validates :current_hp, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(status: 'active').where('ends_at > ?', Time.current) }

  after_initialize :set_defaults, if: :new_record?

  BOSS_SKILLS = {
    'shadow_mist' => { name: "影の霧", effect: "集中効率が半分になるもこ...", duration: 20.minutes },
    'memory_leak' => { name: "メモリリーク", effect: "ボスのHPが見えなくなるもこ！", duration: 15.minutes },
    'primal_roar' => { name: "咆哮", effect: "受けるダメージが2倍になるもこ！", duration: 10.minutes }
  }

  def set_defaults
    self.participants_data ||= {}
    self.status ||= 'active'
    self.current_hp ||= self.max_hp
    self.current_phase ||= 1
  end

  def skill_active?
    active_skill.present? && skill_ends_at.present? && skill_ends_at > Time.current
  end

  def cast_skill!(skill_id = nil)
    skill_id ||= BOSS_SKILLS.keys.sample
    skill = BOSS_SKILLS[skill_id]
    
    update!(
      active_skill: skill_id,
      skill_ends_at: Time.current + skill[:duration]
    )
    
    # Broadcast to world
    ActionCable.server.broadcast("raid_channel", {
      type: "boss_skill_cast",
      skill_id: skill_id,
      skill_name: skill[:name],
      message: "ボスがスキルを放った：#{skill[:name]} ! #{skill[:effect]}"
    })
  end

  def clear_skill!
    update!(active_skill: nil, skill_ends_at: nil)
    ActionCable.server.broadcast("raid_channel", {
      type: "skill_cleared",
      message: "ボスのスキル効果が消えたもこ！"
    })
  end

  def update_phase!
    new_phase = health_percentage <= 50 ? 2 : 1
    if new_phase > current_phase
      self.current_phase = new_phase
      ActionCable.server.broadcast("raid_channel", {
        type: "phase_transition",
        phase: new_phase,
        message: "⚠️ 警告：ボスの形態が変化したもこ！攻撃が激化するもこ！ (PHASE #{new_phase})"
      })
    end
  end

  def health_percentage
    return 0 if max_hp.to_i <= 0
    ((current_hp.to_f / max_hp.to_f) * 100).round(2)
  end

  def leaderboard(limit = 10)
    participants_data.to_a.sort_by { |_, dmg| -dmg }.first(limit)
  end
end
