class User < ApplicationRecord
  include Levelable
  
  has_many :sessions, dependent: :destroy
  has_many :moko_items, dependent: :destroy
  has_many :goal_nodes, dependent: :destroy

  validates :device_id, presence: true, uniqueness: true
  validates :username, presence: true
  validates :level, numericality: { greater_than_or_equal_to: 1 }
  validates :xp, :streak, :coins, :rest_days, numericality: { greater_than_or_equal_to: 0 }

  before_validation :ensure_username

  private

  def ensure_username
    self.username ||= "MokoUser_#{device_id.last(4)}" if device_id.present?
  end
end
