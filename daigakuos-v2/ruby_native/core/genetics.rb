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

      # 🧬 Advanced Genetic Recombination (Phase 66)
      def self.recombine!(raid_state)
        epi = raid_state[:epigenetics]
        ger = raid_state[:germline] || { gamete_health: 1.0 }
        
        epi[:generation_count] += 1
        
        # 🧪 1. Epigenetic Persistence
        # 30% of parent's methylation markers are 'locked' into the offspring
        epi[:methylation].transform_values! { |v| (v * 0.3).round(4) }
        
        # 🧱 2. Congenital Defects
        # If parental gamete health was poor, the child starts with organ scars
        if ger[:gamete_health] < 0.6
          defect_load = (1.0 - ger[:gamete_health]) * 0.2
          raid_state[:physiology][:fibrosis].transform_values! { |v| [v + defect_load, 0.5].min }
        end
        
        # 🧬 3. Reset Phenotype
        # Full phenotypic recalculation will happen on next tick
        raid_state[:phenotype] = nil
        
        raid_state
      end
    end
  end
end
