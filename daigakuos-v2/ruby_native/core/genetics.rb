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
        hormones = phys[:hormones]
        stress = phys[:organ_stress]
        
        # 🧪 1. Epigenetic Drift (Methylation)
        # Chronic cortisol (stress) causes methylation (gene silencing/shifting)
        GENES.each do |gene|
          # High cortisol increases methylation probability
          drift = (hormones[:cortisol] * 0.001 * dt_hours)
          epi[:methylation][gene] = [epi[:methylation][gene] + drift, 1.0].min
        end
        
        # 🧬 2. Calculate Phenotype (Expressed Traits)
        # Phenotype = Genotype * (1.0 - Methylation * Coefficient)
        # Note: High metabolic rate methylation actually lowers the expressed rate (saving energy)
        bloodline = raid_state[:bloodline]
        
        raid_state[:phenotype] = {
          bone_density: (bloodline[:bone_density] * (1.0 - epi[:methylation][:bone_density] * 0.3)).round(3),
          metabolic_rate: (bloodline[:metabolic_rate] * (1.0 - epi[:methylation][:metabolic_rate] * 0.5)).round(3),
          lung_capacity: (bloodline[:lung_capacity] * (1.0 - epi[:methylation][:lung_capacity] * 0.2)).round(3)
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
