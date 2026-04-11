# frozen_string_literal: true

module Moko
  module Bio
    # 🛡️ Immunology: Cellular Defense System
    # Models the response to environmental decay and pathogens.
    
    class ImmunologyEngine
      BASE_LEUKOCYTE_COUNT = 5000.0 # Standard cells/uL

      def self.initialize_immunology(raid_state)
        raid_state[:immunology] ||= {
          leukocyte_activity: 0.1,  # 0.0 to 1.0 (Immune activation)
          antibody_titer: 0.05,     # Specific resistance
          efficiency: 1.0,          # General immune health
          antigen_load: 0.0
        }
      end

      def self.tick(raid_state, env_state, dt_hours)
        imm = raid_state[:immunology]
        metab = raid_state[:metabolism]
        toxins = (env_state[:toxins] || 0.0) / 100.0
        
        # 🧪 1. Antigen Recognition
        # Toxins act as antigens that trigger immune response
        imm[:antigen_load] = [imm[:antigen_load] + (toxins * 0.1) - (imm[:leukocyte_activity] * dt_hours), 0.0].max
        
        # 🛡️ 2. Leukocyte Response (White Blood Cell Activation)
        # Activation depends on antigen load and available ATP
        target_activity = [imm[:antigen_load] * 2.0, 1.0].min
        # Immune recruitment has a delay/cost
        imm[:leukocyte_activity] = (imm[:leukocyte_activity] + (target_activity - imm[:leukocyte_activity]) * dt_hours).clamp(0.01, 1.0)
        
        # ⚡ 3. ATP Cost of Defense
        # Active immune systems consume significant energy
        immune_drain = (imm[:leukocyte_activity] * 20.0) # kcal/hr
        metab[:glucose] = [metab[:glucose] - (immune_drain * dt_hours), 0.0].max
        
        # 🛡️ 4. Antibody Production (Long-term adaptation)
        # Antibodies build up slowly during sustained exposure
        if toxins > 0.4
          imm[:antibody_titer] = [imm[:antibody_titer] + (0.01 * dt_hours), 1.0].min
        else
          # Slow decay of antibodies without stimulus
          imm[:antibody_titer] = [imm[:antibody_titer] - (0.001 * dt_hours), 0.05].max
        end
        
        # ⚖️ 5. Shielding Effect
        # Immune system 'screens' toxins to protect organs
        # Final toxin impact is reduced by immune activity and antibodies
        imm[:protection_factor] = (imm[:leukocyte_activity] * 0.5 + imm[:antibody_titer] * 0.5).clamp(0.0, 0.9)
        
        raid_state
      end
    end
  end
end
