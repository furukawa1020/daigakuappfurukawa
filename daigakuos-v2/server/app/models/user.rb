class User < ApplicationRecord
  include Levelable
  include Activable
  
  has_many :sessions, dependent: :destroy
  has_many :moko_items, dependent: :destroy
  has_many :goal_nodes, dependent: :destroy

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

  private

  def ensure_mood
    self.moko_mood ||= "sleepy"
  end

  def ensure_username
    self.username ||= "MokoUser_#{device_id.last(4)}" if device_id.present?
  end
end
