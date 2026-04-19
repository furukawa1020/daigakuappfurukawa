# frozen_string_literal: true

module Moko
  module Bio
    # 🛡️ Immunology: Cellular Defense System
    # Models the response to environmental decay and pathogens.
    
    class ImmunologyEngine
      BASE_LEUKOCYTE_COUNT = 5000.0 # Standard cells/uL

      def self.initialize_immunology(raid_state)
        raid_state[:immunology] ||= {
          leukocyte_activity: 0.1,  # Innate
          antibody_vault: {},       # Adaptive Memory: { moko_virus_v1: 0.05 }
          efficiency: 1.0,
          antigen_load: 0.0,
          protection_factor: 0.0
        }
        raid_state[:immunology][:antibody_vault] ||= {}
      end

      def self.tick(raid_state, env_state, dt_hours)
        imm = raid_state[:immunology]
        metab = raid_state[:metabolism]
        infections = raid_state[:infections] || {}
        toxins = (env_state[:toxins] || 0.0) / 100.0
        
        # 🧪 1. Antigen Recognition (General + Specific)
        total_toxin_burden = toxins + (raid_state[:infectious_burden] || 0.0)
        imm[:antigen_load] = [imm[:antigen_load] + (total_toxin_burden * 0.1) - (imm[:leukocyte_activity] * dt_hours * 2.0), 0.0].max
        
        # 🛡️ 2. Leukocyte Response (Innate)
        target_activity = [imm[:antigen_load] * 1.5, 1.0].min
        imm[:leukocyte_activity] = (imm[:leukocyte_activity] + (target_activity - imm[:leukocyte_activity]) * dt_hours * 0.5).clamp(0.01, 1.0)
        
        # 🧠 3. Adaptive Immunity (Specific Antibody Evolution)
        infections.each do |strain, load|
          next if load <= 0
          
          # 📈 Production: Sustained exposure builds specific antibody
          production_rate = load * 0.05 # 5% per hour of max load
          imm[:antibody_vault][strain] = [ (imm[:antibody_vault][strain] || 0.0) + production_rate * dt_hours, 1.0 ].min
          
          # ⚔️ Neutralization: Specific antibody kills pathogens faster than general leukocytes
          kill_power = (imm[:antibody_vault][strain] || 0.0) * 1.5 + (imm[:leukocyte_activity] * 0.5)
          infections[strain] = [ load - (kill_power * dt_hours), 0.0 ].max
        end
        
        # 🛡️ 4. Shielding Effect (Phase 69/70 Synergy)
        # 🦠 Microbial Synergy: Symbiotic ratio boosts barrier
        mic = raid_state[:microbiome] || { symbiotic_ratio: 0.8 }
        microbial_bonus = (mic[:symbiotic_ratio] * 0.5 + 0.6)
        
        avg_antibody_level = imm[:antibody_vault].values.empty? ? 0.05 : (imm[:antibody_vault].values.sum / [imm[:antibody_vault].size, 1].max)
        base_protection = (imm[:leukocyte_activity] * 0.4 + avg_antibody_level * 0.6)
        imm[:protection_factor] = (base_protection * microbial_bonus).clamp(0.0, 0.95)
        
        # ⚡ 5. Metabolic Cost
        immune_drain = (imm[:leukocyte_activity] * 15.0) + (imm[:antibody_vault].size * 2.0)
        metab[:glucose] = [metab[:glucose] - (immune_drain * dt_hours), 0.0].max
        
        raid_state
      end
    end
  end
end
