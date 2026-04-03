class GlobalRaid < ApplicationRecord
  serialize :participants_data, coder: JSON
  
  validates :title, presence: true
  validates :max_hp, numericality: { greater_than: 0 }
  validates :current_hp, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(status: 'active').where('ends_at > ?', Time.current) }

  after_initialize :set_defaults, if: :new_record?

  def set_defaults
    self.participants_data ||= {}
    self.status ||= 'active'
    self.current_hp ||= self.max_hp
  end

  def health_percentage
    return 0 if max_hp.to_i <= 0
    ((current_hp.to_f / max_hp.to_f) * 100).round(2)
  end

  def leaderboard(limit = 10)
    participants_data.to_a.sort_by { |_, dmg| -dmg }.first(limit)
  end
end
