class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :moko_items, dependent: :destroy
  has_many :goal_nodes, dependent: :destroy

  validates :device_id, presence: true, uniqueness: true
  validates :level, numericality: { greater_than_or_equal_to: 1 }
  validates :xp, :streak, :coins, :rest_days, numericality: { greater_than_or_equal_to: 0 }
end
