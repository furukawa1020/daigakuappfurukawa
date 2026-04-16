class PartyMembership < ApplicationRecord
  belongs_to :user
  belongs_to :party
  
  validates :user_id, uniqueness: true # A user can only be in one party at a time
end
