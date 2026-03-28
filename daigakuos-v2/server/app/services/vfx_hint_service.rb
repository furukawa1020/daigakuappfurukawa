class VFXHintService
  # Suggest visual effects based on user events
  def self.determine_hints(user)
    hints = []
    
    # 1. Level up hint
    if user.saved_changes.include?(:level)
      hints << { id: "evolution_glow", intensity: "high" }
    end
    
    # 2. Focus streak hint
    if user.streak > 5
      hints << { id: "shiny_sparkle", color: "gold" }
    end
    
    # 3. Mood based hint
    if user.moko_mood == "focus_god"
      hints << { id: "fire_aura", color: "blue" }
    end
    
    hints
  end
end
