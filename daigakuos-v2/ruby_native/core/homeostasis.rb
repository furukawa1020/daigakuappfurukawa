# frozen_string_literal: true

module Moko
  module Bio
    # ⚖️ Homeostasis: Internal Equilibrium Management
    # Models pH balance and Thermal regulation.
    
    class HomeostasisEngine
      IDEAL_PH = 7.4
      IDEAL_TEMP = 38.5 # Celsius

      def self.initialize_homeostasis(raid_state)
        raid_state[:environment][:pH] ||= IDEAL_PH
        raid_state[:environment][:body_temp] ||= IDEAL_TEMP
      end

      def self.tick(raid_state, dt_hours)
        metab = raid_state[:metabolism]
        hormones = raid_state[:physiology][:hormones]
        env = raid_state[:environment]
        
        # 🌡️ 1. Thermal Regulation
        # Metabolic heat generation based on adrenaline and exertion
        heat_gen = (hormones[:adrenaline] * 5.0) + (metab[:atp_reserves] * 1.0)
        # Cooling: Passive dissipation (simplified)
        cooling = (env[:body_temp] - IDEAL_TEMP) * 0.5
        env[:body_temp] = (env[:body_temp] + (heat_gen - cooling) * dt_hours).round(2)
        
        # ⚖️ 2. pH Balance (Acid-Base Equilibrium)
        # Lactate acts as an acid, lowering pH (Acidosis)
        acid_load = (metab[:lactate_level] / 100.0)
        # Bicarbonate Buffer: Passive neutralization
        buffer_efficiency = (env[:oxygen] / 100.0)
        env[:pH] = (IDEAL_PH - (acid_load * 0.4) + (buffer_efficiency * 0.1)).clamp(6.8, 7.8).round(2)
        
        # 🧪 Impact on Physics
        # High acidosis (low pH) reduces muscle contractile force
        # This will be used as a multiplier in BioPhysics
        raid_state[:homeostatic_modifiers] = {
          muscle_force: (1.0 - (IDEAL_PH - env[:pH]).abs * 2.0).clamp(0.4, 1.2),
          reaction_speed: (1.0 - (IDEAL_TEMP - env[:body_temp]).abs * 0.05).clamp(0.5, 1.1),
          oxygen_efficiency: raid_state.dig(:homeostatic_modifiers, :oxygen_efficiency) || 1.0
        }
        
        raid_state
      end
    end
  end
end
