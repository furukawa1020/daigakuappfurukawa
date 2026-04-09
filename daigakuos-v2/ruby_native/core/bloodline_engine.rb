# frozen_string_literal: true

class BloodlineEngine
  # 🧬 Biological Inheritance & Trait Management
  # Grounded in physical parameters: Bone Density, Muscle Fiber, and Lung Capacity.
  
  DEFAULT_GENOME = {
    bone_density: 1.0,      # Resilience to impact
    muscle_type: :balanced, # :twitch (fast/weak) or :tonic (slow/strong)
    lung_capacity: 1.0,     # Stamina recovery rate
    metabolic_rate: 1.0     # How fast hunger grows
  }.freeze

  def self.initialize_bloodline(raid_state)
    raid_state[:bloodline] ||= DEFAULT_GENOME.dup
  end

  def self.evolve!(raid_state, exposure_log)
    bloodline = raid_state[:bloodline] ||= DEFAULT_GENOME.dup
    
    # Adapt based on historical exposure (Natural Selection)
    # If the monster took high damage, bone density increases
    if exposure_log.count { |e| e[:damage_taken] > 50 } > 5
      bloodline[:bone_density] = (bloodline[:bone_density] + 0.05).round(3)
    end
    
    # If the environment was mostly toxic, metabolic rate adapts
    if exposure_log.count { |e| e[:toxin_load] > 0.6 } > 10
      bloodline[:metabolic_rate] = (bloodline[:metabolic_rate] * 0.95).round(3)
    end

    # Mutation
    mutate!(bloodline)
  end

  def self.mutate!(bloodline)
    # Random drift in physical traits
    bloodline[:lung_capacity] = (bloodline[:lung_capacity] + (rand - 0.5) * 0.1).clamp(0.5, 2.0).round(3)
    
    # Random flip in muscle fiber dominant type
    if rand < 0.05
      bloodline[:muscle_type] = [:twitch, :tonic, :balanced].sample
    end
  end

  def self.apply_biology(raid_state, base_stats)
    bloodline = raid_state[:bloodline] || DEFAULT_GENOME
    
    # Adjust max HP based on bone density
    base_stats[:max_hp] = (base_stats[:max_hp] * bloodline[:bone_density]).to_i
    
    # Adjust behavior speed based on muscle type
    # (These constants will be used by the Physics Engine later)
    raid_state[:physics_constants] = {
      flap_frequency: bloodline[:muscle_type] == :twitch ? 8.0 : 4.0,
      impact_weight: bloodline[:muscle_type] == :tonic ? 1.5 : 1.0
    }
  end
end
