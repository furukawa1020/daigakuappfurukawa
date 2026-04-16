require_relative 'skill_registry'

class ActionPatterns
  def self.select_action(raid_phase, global_entropy)
    skill_id = if global_entropy > 0.8 && raid_phase >= 2
       rand(100) < 20 ? :entropy_surge : :chaos_breath
    elsif global_entropy > 0.5
      rand(100) < 40 ? :chaos_breath : :data_void
    elsif raid_phase == 3
      [:chaos_breath, :data_void, :normal_attack].sample
    else
      rand(100) < 30 ? :data_void : :normal_attack
    end
    
    SkillRegistry.get(skill_id)
  end
end
