# frozen_string_literal: true

module Moko
  module Bio
    # 🧬 Physiology: Tissue-Level Organ Dynamics
    # This module models the health and capacity of specific biological systems.
    
    # 🧠 Nervous System: Conduction velocity and signal integrity
    NeuralPlexus = Struct.new(:conduction_velocity, :synaptic_stress, :reflex_latency, keyword_init: true)
    
    # ❤️ Circulatory System: Oxygen delivery and waste removal
    CardiacSystem = Struct.new(:pulse_rate, :blood_pressure_delta, :oxygen_saturation, keyword_init: true)
    
    # 🧪 Endocrine System: Hormonal concentrations
    HormonalState = Struct.new(:adrenaline, :cortisol, :insulin, :metabolic_activator, keyword_init: true)

    class PhysiologyEngine
      DEFAULT_NEURAL = NeuralPlexus.new(conduction_velocity: 1.0, synaptic_stress: 0.0, reflex_latency: 0.0).freeze
      DEFAULT_CARDIAC = CardiacSystem.new(pulse_rate: 60, blood_pressure_delta: 0.0, oxygen_saturation: 100.0).freeze
      DEFAULT_HORMONES = HormonalState.new(adrenaline: 0.05, cortisol: 0.1, insulin: 0.5, metabolic_activator: 1.0).freeze

      def self.initialize_physiology(raid_state)
        raid_state[:physiology] ||= {
          neural: DEFAULT_NEURAL.to_h,
          cardiac: DEFAULT_CARDIAC.to_h,
          hormones: DEFAULT_HORMONES.to_h,
          organ_stress: { neural: 0.0, cardiac: 0.0, hepatic: 0.0, renal: 0.0 }
        }
      end

      def self.tick(raid_state, env_state, dt_hours)
        phys = raid_state[:physiology]
        hormones = phys[:hormones]
        stress = phys[:organ_stress]
        
        # 🌪️ Environmental Stress Impacts
        toxin_ratio = (env_state[:toxins] || 0.0) / 100.0
        
        # 1. Hormonal Feedback Loops
        # Cortisol (Stress) increases with environmental toxins
        hormones[:cortisol] = [hormones[:cortisol] + (toxin_ratio * 0.1 * dt_hours), 1.0].min
        
        # Adrenaline decays slowly unless triggered (triggered by damage or high chaos)
        hormones[:adrenaline] = [hormones[:adrenaline] - (0.2 * dt_hours), 0.05].max
        
        # 2. Organ Decay (Long-term impact of toxins and stress)
        stress[:hepatic] = [stress[:hepatic] + (toxin_ratio * 0.05 * dt_hours) - (0.01 * dt_hours), 0.0].max
        stress[:neural] = [stress[:neural] + (hormones[:cortisol] * 0.02 * dt_hours), 0.0].max
        
        # 3. Functional Impact (Signal conduction)
        # Neural conduction drops as toxins and neural stress accumulate
        phys[:neural][:conduction_velocity] = (1.0 - (toxin_ratio * 0.3) - (stress[:neural] * 0.4)).clamp(0.2, 1.0).round(3)
        phys[:neural][:reflex_latency] = (1.0 - phys[:neural][:conduction_velocity]).round(3)
        
        # 4. Cardiac Output
        # Pulse increases with adrenaline
        phys[:cardiac][:pulse_rate] = (60 + (hormones[:adrenaline] * 120)).to_i
        phys[:cardiac][:oxygen_saturation] = (env_state[:oxygen] * (1.0 - stress[:cardiac])).clamp(0.0, 100.0).round(1)

        raid_state
      end

      # Called when heavy damage or chaos session starts
      def self.trigger_adrenaline_surge(raid_state, intensity = 0.5)
        raid_state[:physiology][:hormones][:adrenaline] = [raid_state[:physiology][:hormones][:adrenaline] + intensity, 1.0].min
      end
    end
  end
end
