module Levelable
  extend ActiveSupport::Concern

  # The `included` block runs in the context of the class that includes this module (e.g. User).
  # This is classic Ruby metaprogramming that keeps models clean.
  included do
    before_save :calculate_level_from_xp, if: :xp_changed?
  end

  def calculate_level_from_xp
    # Every 1000 XP is a level. 
    # This automatically updates the level before saving to the database.
    new_level = (self.xp / 1000) + 1
    self.level = new_level if new_level > self.level
  end

  def xp_to_next_level
    current_tier = self.level * 1000
    current_tier - self.xp
  end
end
