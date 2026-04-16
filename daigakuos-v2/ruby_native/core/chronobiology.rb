# frozen_string_literal: true

module Moko
  module Bio
    # ⏰ Chronobiology: 24-Hour Circadian System
    # Models the biological clock and restorative sleep cycles.
    
    class ChronobiologyEngine
      def self.initialize_chrono(raid_state)
        raid_state[:chrono] ||= {
          internal_hour: 12.0, # 0.0 to 24.0
          melatonin_level: 0.1,
          cycle_type: :diurnal, # Diurnal (Day-active) or Nocturnal
          alertness: 1.0
        }
      end

      def self.tick(raid_state, dt_hours)
        chr = raid_state[:chrono]
        
        # 🌙 1. Update Internal Clock
        chr[:internal_hour] = (chr[:internal_hour] + dt_hours) % 24.0
        
        # 🧬 2. Melatonin Dynamics
        # High at night (20:00 to 06:00)
        is_night = chr[:internal_hour] > 20.0 || chr[:internal_hour] < 6.0
        target_melatonin = is_night ? 0.9 : 0.05
        chr[:melatonin_level] = (chr[:melatonin_level] + (target_melatonin - chr[:melatonin_level]) * 0.2 * dt_hours).clamp(0.0, 1.0)
        
        # 😴 3. Alertness and Sleep Pressure
        # Alertness drops with high melatonin
        chr[:alertness] = (1.0 - chr[:melatonin_level]).clamp(0.1, 1.0)
        
        # 💖 4. Restorative Effect
        # If alertness is very low, the monster enters 'Restorative Sleep'
        raid_state[:is_sleeping] = chr[:alertness] < 0.3
        
        raid_state
      end

      # Factor for tissue repair speed
      def self.repair_multiplier(raid_state)
        raid_state[:is_sleeping] ? 4.0 : 1.0
      end
    end
  end
end
