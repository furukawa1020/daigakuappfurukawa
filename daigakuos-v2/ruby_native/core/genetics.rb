# frozen_string_literal: true

module Moko
  module Bio
    # 🧬 Genetics: Epigenetic & Phenotypic Expression Engine
    # Models the impact of chronic stress on DNA Methylation.
    
    class GeneticsEngine
      GENES = [:bone_density, :metabolic_rate, :lung_capacity]

      def self.initialize_genetics(raid_state)
        raid_state[:epigenetics] ||= {
          methylation: { bone_density: 0.0, metabolic_rate: 0.0, lung_capacity: 0.0 },
          expression_bias: 1.0,
          generation_count: 1
        }
      end

      def self.tick(raid_state, dt_hours)
        epi = raid_state[:epigenetics]
        phys = raid_state[:physiology]
        return raid_state unless epi && phys
        
        hormones = phys[:hormones]
        stress = phys[:organ_stress]
        bloodline = raid_state[:bloodline] || {}
        
        # 🧪 1. Epigenetic Drift (Methylation)
        GENES.each do |gene|
          drift = (hormones[:cortisol] || 0.1) * 0.001 * dt_hours
          epi[:methylation][gene] = [(epi[:methylation][gene] || 0.0) + drift, 1.0].min
        end
        
        # 🧬 2. Calculate Phenotype (Expressed Traits)
        raid_state[:phenotype] = {
          bone_density: ((bloodline[:bone_density] || 1.0) * (1.0 - (epi[:methylation][:bone_density] || 0.0) * 0.3)).round(4),
          metabolic_rate: ((bloodline[:metabolic_rate] || 1.0) * (1.0 - (epi[:methylation][:metabolic_rate] || 0.0) * 0.5)).round(4),
          lung_capacity: ((bloodline[:lung_capacity] || 1.0) * (1.0 - (epi[:methylation][:lung_capacity] || 0.0) * 0.2)).round(4)
        }
        
        raid_state
      end

      # Genetic refresh mechanic (Phase 63 Rebirth)
      def self.recombine!(raid_state)
        epi = raid_state[:epigenetics]
        epi[:generation_count] += 1
        # Some methylation persists (Epigenetic inheritance)
        epi[:methylation].transform_values! { |v| v * 0.5 } 
      end
    end
  end
end
