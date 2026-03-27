class MokoEvolutionService
  # Evolution stages driven by Ruby logic
  STAGES = {
    1 => { name: "もこたま", min_level: 1 },
    2 => { name: "ぷにもこ", min_level: 5 },
    3 => { name: "てちもこ", min_level: 10 },
    4 => { name: "のびもこ", min_level: 20 },
    5 => { name: "メガもこ", min_level: 50 },
    6 => { name: "アルティメットもこ", min_level: 100 }
  }.freeze

  def self.check_evolution(user)
    current_stage = user.level / 10 + 1 # Simple example logic
    current_stage = [current_stage, 6].min
    
    stage_data = STAGES[current_stage]
    
    # Logic for branching based on focus quality
    avg_quality = user.sessions.average(:quality) || 0
    special_trait = avg_quality > 4 ? "集中マスター" : "努力家"
    
    {
      stage: current_stage,
      name: stage_data[:name],
      trait: special_trait,
      unlocked: user.level >= stage_data[:min_level]
    }
  end
end
