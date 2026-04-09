# frozen_string_literal: true

module Moko
  module Bio
    # 🧬 Biological Inheritance & Trait Management
    # Uses Sigmoid Adaptation models for 'Proper' natural selection.
    
    Genome = Struct.new(:bone_density, :muscle_type, :lung_capacity, :metabolic_rate, keyword_init: true)

    class BloodlineEngine
      DEFAULT_GENOME = Genome.new(
        bone_density: 1.0,
        muscle_type: :balanced, 
        lung_capacity: 1.0,
        metabolic_rate: 1.0
      ).freeze

      def self.initialize_bloodline(raid_state)
        raid_state[:bloodline] ||= DEFAULT_GENOME.to_h
      end

      # 🧬 Proper Adaptation Model: Sigmoid Growth
      # Avoids linear drift; traits approach a biological limit asymptotically.
      def self.evolve!(raid_state, exposure_log)
        current = raid_state[:bloodline]
        
        # 🦴 Bone Density Adaptation (Asymptotic)
        # S(x) = L / (1 + e^-k(x-x0))
        damage_exposure = exposure_log.select { |e| e[:damage_taken] > 50 }.size
        if damage_exposure > 0
          adaptation_factor = sigmoid(damage_exposure, 0.1, 5)
          current[:bone_density] = (1.0 + adaptation_factor * 0.5).round(3)
        end
        
        # 🍕 Metabolic Adaptation
        toxin_exposure = exposure_log.select { |e| e[:toxin_load] > 0.6 }.size
        if toxin_exposure > 0
          metabolic_shift = sigmoid(toxin_exposure, 0.05, 10)
          current[:metabolic_rate] = (1.0 - metabolic_shift * 0.3).round(3)
        end

        mutate!(current)
      end

      def self.apply_biology(raid_state, base_stats)
        bloodline = raid_state[:bloodline] || DEFAULT_GENOME.to_h
        
        # Bone density affects structural integrity (Max HP)
        base_stats[:max_hp] = (base_stats[:max_hp] * bloodline[:bone_density]).to_i
        
        # Muscle type and Lung capacity drive physical constants
        raid_state[:physics_constants] = {
          frequency_mult: bloodline[:muscle_type] == :twitch ? 1.5 : 0.8,
          efficiency: bloodline[:lung_capacity],
          stiffness: bloodline[:bone_density]
        }
      end

      private

      def self.sigmoid(x, k, x0)
        1.0 / (1.0 + Math.exp(-k * (x - x0)))
      end

      def self.mutate!(bloodline)
        # Random genetic drift (Standard deviation based)
        bloodline[:lung_capacity] = (bloodline[:lung_capacity] + (rand - 0.5) * 0.05).clamp(0.5, 2.0).round(3)
        bloodline[:muscle_type] = [:twitch, :tonic, :balanced].sample if rand < 0.02
      end
    end
  end
end
