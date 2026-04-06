class Party < ApplicationRecord
  has_many :party_memberships, dependent: :destroy
  has_many :users, through: :party_memberships
  
  validates :name, presence: true, uniqueness: true
end
