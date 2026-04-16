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
          organ_stress: { 
            neural: 0.0, cardiac: 0.0, hepatic: 0.0, renal: 0.0 
          },
          fibrosis: { # Permanent Damage Layer (Phase 64)
            neural: 0.0, cardiac: 0.0, hepatic: 0.0, renal: 0.0 
          },
          cellular_age: 0.0,
          mitochondrial_decay: 0.0
        }
      end

      def self.tick(raid_state, env_state, dt_hours)
        phys = raid_state[:physiology]
        hormones = phys[:hormones]
        stress = phys[:organ_stress]
        
        # ⏳ 0. Mitochondrial Decay (Aging Layer)
        # Exertion accelerates cellular aging
        phys[:cellular_age] += dt_hours
        decay_rate = (hormones[:adrenaline] * 0.0001) + (phys[:organ_stress].values.sum * 0.00001)
        phys[:mitochondrial_decay] = [phys[:mitochondrial_decay] + decay_rate * dt_hours, 0.5].min
        
        # Metabolic Activator is capped by decay
        hormones[:metabolic_activator] = (1.0 - phys[:mitochondrial_decay]).round(4)
        
        # 🌪️ Environmental Stress Impacts
        toxin_ratio = (env_state[:toxins] || 0.0) / 100.0
        
        # 1. Hormonal Feedback Loops
        # Cortisol (Stress) increases with environmental toxins
        hormones[:cortisol] = [hormones[:cortisol] + (toxin_ratio * 0.1 * dt_hours), 1.0].min
        
        # Adrenaline decays slowly unless triggered (triggered by damage or high chaos)
        hormones[:adrenaline] = [hormones[:adrenaline] - (0.2 * dt_hours), 0.05].max
        
        # 2. Organ Decay & Repair (Phase 64: Chrono-linked)
        # Toxin-induced stress
        stress[:hepatic] = [stress[:hepatic] + (toxin_ratio * 0.05 * dt_hours), 1.0].min
        stress[:neural] = [stress[:neural] + (hormones[:cortisol] * 0.02 * dt_hours), 1.0].min
        
        # Repair logic: Depends on Sleep/Rest multiplier
        # (Requires ChronobiologyEngine to be required in moko_engine)
        repair_mult = raid_state[:is_sleeping] ? 4.0 : 0.5
        repair_rate = 0.01 * repair_mult * dt_hours
        
        [:neural, :cardiac, :hepatic, :renal].each do |organ|
          stress[organ] = [stress[organ] - repair_rate, 0.0].max
          
          # 💎 2b. Fibrosis Conversion: If stress > 0.8, some becomes permanent
          if stress[organ] > 0.8
            conversion = (stress[organ] - 0.8) * 0.01 * dt_hours
            phys[:fibrosis][organ] = [phys[:fibrosis][organ] + conversion, 1.0].min
          end
        end
        
        # 3. Functional Impact (Signal conduction)
        # Actual capacity is restricted by Fibrosis
        neural_perf = (1.0 - toxin_ratio * 0.3 - stress[:neural] * 0.4 - phys[:fibrosis][:neural])
        phys[:neural][:conduction_velocity] = neural_perf.clamp(0.1, 1.0).round(3)
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
