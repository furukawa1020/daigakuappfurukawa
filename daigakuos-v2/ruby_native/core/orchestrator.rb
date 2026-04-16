# frozen_string_literal: true

module Moko
  module Bio
    # 🎮 Orchestrator: Central Bio-Engine Controller
    # Single entry point for all biological simulation. Self-healing & crash-resistant.

    class Orchestrator
      # Strict execution order — biologically motivated
      TICK_ORDER = [
        :MicrobiomeEngine,
        :PhysiologyEngine,
        :MetabolismEngine,
        :HomeostasisEngine,
        :ImmunologyEngine,
        :GeneticsEngine,
        :SensoryEngine,
        :ChronobiologyEngine,
        :SkeletonEngine,
        :AnatomyEngine,
        :GermlineEngine,
      ].freeze

      # ──────────────────────────────────────────────
      # 1. SELF-HEALING INITIALIZER
      # Fills in any missing keys without overwriting existing live data.
      # ──────────────────────────────────────────────
      def self.ensure_state!(raid_state)
        # Microbiome (Phase 68)
        raid_state[:microbiome] ||= {}
        mic = raid_state[:microbiome]
        mic[:flora_diversity] ||= 1.0
        mic[:symbiotic_ratio] ||= 0.8
        mic[:endotoxin_level] ||= 0.0
        mic[:fermentation_rate] ||= 1.0
        mic[:neuroactive_metabolites] ||= { irritability: 0.0, calmness: 0.1 }

        raid_state[:bloodline] ||= {
          bone_density: 1.0, muscle_type: :balanced,
          lung_capacity: 1.0, metabolic_rate: 1.0
        }

        # Physiology
        raid_state[:physiology] ||= {}
        phys = raid_state[:physiology]
        phys[:neural]       ||= { conduction_velocity: 1.0, synaptic_stress: 0.0, reflex_latency: 0.0 }
        phys[:cardiac]      ||= { pulse_rate: 60, blood_pressure_delta: 0.0, oxygen_saturation: 100.0 }
        phys[:hormones]     ||= { adrenaline: 0.05, cortisol: 0.1, insulin: 0.5, metabolic_activator: 1.0 }
        phys[:organ_stress] ||= { neural: 0.0, cardiac: 0.0, hepatic: 0.0, renal: 0.0 }
        phys[:fibrosis]     ||= { neural: 0.0, cardiac: 0.0, hepatic: 0.0, renal: 0.0 }
        phys[:cellular_age]         ||= 0.0
        phys[:mitochondrial_decay]  ||= 0.0

        # Metabolism
        raid_state[:metabolism] ||= {}
        meta = raid_state[:metabolism]
        meta[:glucose]              ||= 100.0
        meta[:atp_reserves]         ||= 1.0
        meta[:lactate_level]        ||= 0.0
        meta[:efficiency]           ||= 1.0
        meta[:last_metabolic_state] ||= :stable

        # Homeostasis
        raid_state[:homeostatic_modifiers] ||= {
          muscle_force: 1.0, reaction_speed: 1.0, oxygen_efficiency: 1.0
        }

        # Immunology
        raid_state[:immunology] ||= {}
        imm = raid_state[:immunology]
        imm[:leukocyte_activity] ||= 0.1
        imm[:antibody_titer]     ||= 0.0
        imm[:protection_factor]  ||= 0.0

        # Epigenetics / Genetics
        raid_state[:epigenetics] ||= {}
        epi = raid_state[:epigenetics]
        epi[:methylation]     ||= { bone_density: 0.0, metabolic_rate: 0.0, lung_capacity: 0.0 }
        epi[:expression_bias] ||= 1.0
        epi[:generation_count]||= 1
        raid_state[:phenotype] ||= {}

        # Sensory
        raid_state[:sensory] ||= {}
        sen = raid_state[:sensory]
        sen[:chemo_sensitivity]  ||= 1.0
        sen[:signal_noise_floor] ||= 0.05
        sen[:last_perception]    ||= { toxins: 0.0, oxygen: 50.0 }
        raid_state[:perception]  ||= { toxins: 0.0, oxygen: 50.0 }

        # Chronobiology
        raid_state[:chrono] ||= {}
        chr = raid_state[:chrono]
        chr[:internal_hour]  ||= 12.0
        chr[:melatonin_level]||= 0.1
        chr[:cycle_type]     ||= :diurnal
        chr[:alertness]      ||= 1.0
        raid_state[:is_sleeping] ||= false

        # Skeleton
        raid_state[:skeleton] ||= {}
        skl = raid_state[:skeleton]
        skl[:stress_level]   ||= 0.0
        skl[:fractures]      ||= []
        skl[:integrity]      ||= 1.0
        skl[:calcium_reserves]||= 1.0

        # Anatomy
        raid_state[:anatomy] ||= {}
        ana = raid_state[:anatomy]
        ana[:epithelial] ||= { health: 1.0, barrier_leak: 0.0 }
        ana[:connective] ||= { health: 1.0, elasticity: 1.0 }
        ana[:muscular]   ||= { health: 1.0, peak_power: 1.0 }

        # Germline
        raid_state[:germline] ||= {}
        ger = raid_state[:germline]
        ger[:gamete_health]      ||= 1.0
        ger[:mutagenic_pressure] ||= 0.0
        ger[:genetic_stability]  ||= 1.0

        # Physics
        raid_state[:physics_velocity] ||= 0.0
        raid_state[:behavior_mode]    ||= :grazing

        raid_state
      end

      # ──────────────────────────────────────────────
      # 2. ORDERED TICK (with safety wrap per module)
      # ──────────────────────────────────────────────
      def self.tick(raid_state, env_state, elapsed_hours, physics_velocity = 0.0)
        ensure_state!(raid_state)

        raid_state[:physics_velocity] = physics_velocity

        errors = []

        safe_tick(errors, :Microbiome) { MicrobiomeEngine.tick(raid_state, elapsed_hours) }
        safe_tick(errors, :Physiology) { PhysiologyEngine.tick(raid_state, env_state, elapsed_hours) }
        safe_tick(errors, :Metabolism) { MetabolismEngine.tick(raid_state, elapsed_hours) }
        safe_tick(errors, :Homeostasis){ HomeostasisEngine.tick(raid_state, elapsed_hours) }
        safe_tick(errors, :Immunology) { ImmunologyEngine.tick(raid_state, env_state, elapsed_hours) }
        safe_tick(errors, :Genetics)   { GeneticsEngine.tick(raid_state, elapsed_hours) }
        safe_tick(errors, :Sensory)    { SensoryEngine.tick(raid_state, env_state, elapsed_hours) }
        safe_tick(errors, :Chrono)     { ChronobiologyEngine.tick(raid_state, elapsed_hours) }
        safe_tick(errors, :Skeleton)   { SkeletonEngine.tick(raid_state, raid_state[:physics_velocity], elapsed_hours) }
        safe_tick(errors, :Anatomy)    { AnatomyEngine.tick(raid_state, elapsed_hours) }
        safe_tick(errors, :Germline)   { GermlineEngine.tick(raid_state, elapsed_hours) }

        raid_state[:_sim_errors] = errors unless errors.empty?
        raid_state
      end

      private

      def self.safe_tick(error_log, name, &block)
        block.call
      rescue => e
        error_log << { module: name, error: e.class.to_s, message: e.message }
      end
    end
  end
end
