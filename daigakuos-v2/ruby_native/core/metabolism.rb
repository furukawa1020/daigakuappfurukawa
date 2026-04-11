# frozen_string_literal: true

module Moko
  module Bio
    # 🍎 Metabolism: Substrate-Level Energy Conversion
    # Models the ATP cycle and caloric partition.
    
    class MetabolismEngine
      # Base metabolic rate (kcal/hr)
      BASE_METABOLIC_RATE = 50.0 

      def self.initialize_metabolism(raid_state)
        raid_state[:metabolism] ||= {
          glucose: 100.0,    # Blood sugar (Nutrients)
          atp_reserves: 1.0, # Energy availability (0.0 to 1.0)
          lactate_level: 0.0, # Metabolic waste
          efficiency: 1.0
        }
      end

      def self.tick(raid_state, dt_hours)
        metab = raid_state[:metabolism]
        bloodline = raid_state[:bloodline] || {}
        hormones = raid_state[:physiology][:hormones]
        
        # 🧪 1. Calculate Energy Demand
        # Demand increases with adrenaline and metabolic rate trait
        demand_mult = 1.0 + (hormones[:adrenaline] * 2.0)
        demand = BASE_METABOLIC_RATE * (bloodline[:metabolic_rate] || 1.0) * demand_mult * dt_hours
        
        # 🩸 2. Glucose Depletion
        # High demand drains glucose
        metab[:glucose] = [metab[:glucose] - (demand * 0.1), 0.0].max
        
        # 🍏 3. ATP Synthesis
        # ATP is regenerated from glucose. If glucose is low, synthesis slows.
        synthesis_rate = [metab[:glucose] / 50.0, 1.0].min
        metab[:atp_reserves] = [metab[:atp_reserves] + (0.5 * synthesis_rate * dt_hours) - (demand * 0.005), 0.0].max.clamp(0.0, 1.0)
        
        # 🌫️ 4. Waste Production (Lactate)
        # Anaerobic metabolism (high demand) produces lactate
        if hormones[:adrenaline] > 0.4
          metab[:lactate_level] = [metab[:lactate_level] + (demand * 0.02), 100.0].min
        else
          # Aerobic recovery: Lactate is cleared slowly
          metab[:lactate_level] = [metab[:lactate_level] - (5.0 * dt_hours), 0.0].max
        end
        
        # ⚖️ 5. Efficiency Impact
        # High lactate (acidosis) reduces overall metabolic efficiency
        metab[:efficiency] = (1.0 - (metab[:lactate_level] / 200.0)).clamp(0.5, 1.0).round(3)
        
        raid_state
      end

      # Called when user interacts/feeds
      def self.ingest_nutrients(raid_state, amount = 20.0)
        raid_state[:metabolism][:glucose] = [raid_state[:metabolism][:glucose] + amount, 150.0].min
      end
    end
  end
end
