class Session < ApplicationRecord
  belongs_to :user

  validates :started_at, presence: true
  validates :duration, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
end
