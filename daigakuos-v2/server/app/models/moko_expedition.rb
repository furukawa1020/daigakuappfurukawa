class MokoExpedition < ApplicationRecord
  belongs_to :user

  validates :name, :difficulty, :required_focus_minutes, :monster_hp, presence: true
  validates :status, inclusion: { in: %w[active completed failed abandoned] }

  scope :active, -> { where(status: 'active') }

  after_initialize :set_defaults, if: :new_record?

  def complete!
    update!(status: 'completed')
  end

  def fail!
    update!(status: 'failed')
  end

  private

  def set_defaults
    self.status ||= 'active'
    self.progress ||= 0.0
    self.rewards ||= {}
  end
end
