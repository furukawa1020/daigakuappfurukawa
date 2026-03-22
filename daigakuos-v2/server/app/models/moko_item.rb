class MokoItem < ApplicationRecord
  belongs_to :user

  validates :item_id, presence: true
end
