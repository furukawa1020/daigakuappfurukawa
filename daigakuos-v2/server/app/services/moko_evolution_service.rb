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
    # 1. Start with basic hardcoded stage as fallback
    current_stage = (user.level / 10 + 1).clamp(1, 6)
    stage_data = STAGES[current_stage]
    
    # 2. Try to apply DSL-based specific dynamic rules
    definition = MokoDefinition::Registry.get('default') # In future, u.current_moko_id
    if definition && definition.behaviors[:evolution_rule]
      # Dynamic evaluation using Ruby magic
      # We pass the user context into the block
      begin
        custom_rule_result = user.instance_exec(&definition.behaviors[:evolution_rule])
        current_stage = custom_rule_result if custom_rule_result.is_a?(Integer)
      rescue => e
        Rails.logger.error "[MokoDSL] Evolution rule error: #{e.message}"
      end
    end
    
    # Final data
    avg_quality = user.sessions.average(:quality) || 0
    special_trait = avg_quality > 4 ? "集中マスター" : "努力家"
    
    {
      stage: current_stage,
      name: STAGES[current_stage][:name],
      trait: special_trait,
      unlocked: user.level >= STAGES[current_stage][:min_level]
    }
  end
end
