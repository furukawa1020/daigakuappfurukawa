# frozen_string_literal: true

module Moko
  module Bio
    # 🦠 Pathogen: Environmental Threat Engine
    # Models specific bacterial, viral, and fungal strains that bloom under certain conditions.
    
    class PathogenEngine
      STRAINS = {
        moko_virus_v1: { name: "モコ・ウイルス α", lethal_threshold: 0.9, metabolic_cost: 0.2 },
        algal_blight:  { name: "藻類腐敗菌", lethal_threshold: 0.8, metabolic_cost: 0.1 },
        neuro_fungus:  { name: "神経真菌", lethal_threshold: 0.7, metabolic_cost: 0.3 }
      }

      def self.initialize_pathogens(raid_state)
        raid_state[:infections] ||= {}
        # e.g., { moko_virus_v1: 0.1 } # key is strain ID, value is 0.0 to 1.0 load
      end

      def self.tick(raid_state, env_state, dt_hours)
        inf = raid_state[:infections]
        toxin_load = (env_state[:toxins] || 0.0) / 100.0
        weather = env_state[:weather] || 'sunny'
        
        # 🌬️ 1. Pathogen Bloom Logic
        # Strains grow based on environmental factors
        
        # Virus Alpha loves high toxins
        if toxin_load > 0.6
          growth = (toxin_load - 0.6) * 0.05 * dt_hours
          inf[:moko_virus_v1] = [ (inf[:moko_virus_v1] || 0.0) + growth, 1.0 ].min
        end
        
        # Algal Blight loves high pH (Alkalosis) and high oxygen
        if (env_state[:pH] || 7.4) > 7.8
          growth = 0.03 * dt_hours
          inf[:algal_blight] = [ (inf[:algal_blight] || 0.0) + growth, 1.0 ].min
        end
        
        # ⚔️ 2. Immune Suppression (Adaptive Immunity Link)
        # We handle the 'Death' of pathogens in the ImmunologyEngine, 
        # but we track the 'Burden' here.
        
        # 🤒 3. Systemic Impact
        # Calculate overall infectious burden for the brain/physiology
        total_burden = inf.values.sum
        raid_state[:infectious_burden] = [total_burden, 1.0].min
        
        raid_state
      end
    end
  end
end
