class User < ApplicationRecord
  include Levelable
  include Activable
  
  has_many :sessions, dependent: :destroy
  has_many :moko_items, dependent: :destroy
  has_many :goal_nodes, dependent: :destroy
  has_many :social_events, dependent: :destroy
  has_many :moko_expeditions, dependent: :destroy
  
  has_one :party_membership, dependent: :destroy
  has_one :party, through: :party_membership

  serialize :boss_archive, coder: JSON
  serialize :passive_buffs, coder: JSON
  serialize :inventory, coder: JSON

  has_many :hunting_quests, dependent: :destroy

  enum role: { tank: 0, healer: 1, dps: 2 }

  def skill_cooldown_remaining
    return 0 unless last_skill_used_at
    remaining = (last_skill_used_at + 1.hour) - Time.current
    [remaining.to_i, 0].max
  end

  def can_use_skill?
    skill_cooldown_remaining <= 0
  end

  validates :device_id, presence: true, uniqueness: true
  validates :username, presence: true
  validates :level, numericality: { greater_than_or_equal_to: 1 }
  validates :xp, :streak, :coins, :rest_days, numericality: { greater_than_or_equal_to: 0 }

  before_validation :ensure_username, :ensure_mood

  def update_moko_mood!
    recent_sessions = sessions.where('started_at > ?', 24.hours.ago)
    total_min = recent_sessions.sum(:duration) || 0
    
    self.moko_mood = if total_min > 120
      "focus_god"
    elsif total_min > 30
      "happy"
    else
      "sleepy"
    end
    save!
  end

  def add_material!(name, amount = 1)
    self.materials ||= {}
    self.materials[name] = (self.materials[name] || 0) + amount
    save!
  end

  private

  def ensure_mood
    self.moko_mood ||= "sleepy"
    self.materials ||= { "moko_stone" => 0, "star_dust" => 0 }
    self.max_sharpness ||= 100
    self.current_sharpness ||= self.max_sharpness
  end

  def sharpen!
    update!(current_sharpness: max_sharpness, last_sharpened_at: Time.current)
  end

  def sharpness_color
    return 'red' if current_sharpness <= 10
    return 'orange' if current_sharpness <= 25
    return 'yellow' if current_sharpness <= 50
    return 'green' if current_sharpness <= 75
    return 'blue' if current_sharpness <= 90
    'white' # Max
  end

  def ensure_username
    self.username ||= "MokoUser_#{device_id.last(4)}" if device_id.present?
  end
end
