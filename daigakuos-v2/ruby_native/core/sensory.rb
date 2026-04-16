# frozen_string_literal: true

module Moko
  module Bio
    # 📡 Sensory: Afferent Neural Transduction Engine
    # Converts raw environment data into 'Perception' signals with biological noise.
    
    class SensoryEngine
      def self.initialize_sensory(raid_state)
        raid_state[:sensory] ||= {
          chemo_sensitivity: 1.0,
          signal_noise_floor: 0.05,
          last_perception: { toxins: 0.0, oxygen: 50.0 }
        }
        raid_state[:perception] ||= raid_state[:sensory][:last_perception].dup
      end

      def self.tick(raid_state, env_state, dt_hours)
        sen = raid_state[:sensory]
        phys = raid_state[:physiology]
        
        # 🧠 1. Neural Noise Factor
        # Lower conduction velocity = higher signal jitter/latency
        conduction = phys[:neural][:conduction_velocity] || 1.0
        jitter_intensity = (1.0 - conduction) * 0.5 + sen[:signal_noise_floor]
        
        # 🧪 2. Chemoreception (Toxins & Oxygen)
        raw_toxins = env_state[:toxins] || 0.0
        raw_oxygen = env_state[:oxygen] || 50.0
        
        # Signals are noisy and have a slight delay (Moving average/persistence)
        # Perception = current + jitter(noise)
        noise_toxins = (rand - 0.5) * jitter_intensity * 20.0
        noise_oxygen = (rand - 0.5) * jitter_intensity * 10.0
        
        target_toxins = (raw_toxins + noise_toxins).clamp(0.0, 100.0)
        target_oxygen = (raw_oxygen + noise_oxygen).clamp(0.0, 100.0)
        
        # 📉 3. Transduction Latency
        # Brain 'adjusts' to new levels slowly based on neural health
        alpha = [0.1 * conduction, 1.0].min
        raid_state[:perception][:toxins] = (raid_state[:perception][:toxins] * (1.0 - alpha) + target_toxins * alpha).round(2)
        raid_state[:perception][:oxygen] = (raid_state[:perception][:oxygen] * (1.0 - alpha) + target_oxygen * alpha).round(2)
        
        raid_state
      end
    end
  end
end
