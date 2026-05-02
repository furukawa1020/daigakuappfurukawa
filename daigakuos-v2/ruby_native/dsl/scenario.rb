# frozen_string_literal: true

require_relative '../core/rust_bridge'

module Moko
  module Bio
    module DSL
      # Ruby Meta-Programming magic to create a beautiful DSL for biological scenarios
      class Scenario
        attr_reader :name, :setup_blocks, :tick_blocks

        def self.define(name, &block)
          scenario = new(name)
          scenario.instance_eval(&block)
          scenario
        end

        def initialize(name)
          @name = name
          @setup_blocks = []
          @tick_blocks = []
        end

        # --- DSL Commands ---

        def environment(&block)
          @setup_blocks << proc do |state|
            env = EnvironmentConfig.new
            env.instance_eval(&block)
            state[:stats]['environment'].merge!(env.to_h)
          end
        end

        def inject_virus(virus_id, initial_load: 0.1)
          @setup_blocks << proc do |state|
            state[:stats]['infections'] ||= {}
            state[:stats]['infections'][virus_id] = initial_load
            puts "🦠 DSL: Injected #{virus_id} (Load: #{initial_load})"
          end
        end

        def feed(food_type)
          @setup_blocks << proc do |state|
            case food_type
            when :sugar
              state[:stats]['metabolism']['glucose'] += 100.0
              state[:stats]['microbiome']['flora_diversity'] -= 0.1
            when :fiber
              state[:stats]['metabolism']['glucose'] += 20.0
              state[:stats]['microbiome']['flora_diversity'] += 0.2
            end
            puts "🍎 DSL: Fed #{food_type}"
          end
        end

        def on_condition(&block)
          @tick_blocks << proc do |state, actions|
            # Provide a helper context to evaluate the condition
            ctx = StateContext.new(state)
            ctx.instance_exec(actions, &block)
          end
        end

        # --- Execution Engine ---

        def run!(duration_hours)
          puts "🧪 Starting Scenario: #{@name} (#{(duration_hours)} hours)"
          
          # Initialize default state
          state = default_bootstrap_state
          
          # Apply setups
          @setup_blocks.each { |b| b.call(state) }

          # Bootstrap tick to apply initial state to Rust
          Moko::Bio::RustBridge.simulate_tick(state, 0.1, 0.0)

          (1..duration_hours).each do |hour|
            # Execute condition checks (which might apply medications or treatments via 'actions')
            actions_queue = ActionsQueue.new(state)
            @tick_blocks.each { |b| b.call(state, actions_queue) }
            
            actions_queue.apply!

            # Tick the Rust engine
            Moko::Bio::RustBridge.simulate_tick(state, 1.0, 0.0)

            # Print concise log
            stats = state[:stats]
            ph = stats['homeostasis']['blood_ph']
            hr = stats['physiology']['cardiac']['pulse_rate']
            vrs = (stats['infections']['moko_virus_v1'] || 0) * 100
            puts "  [Hour #{hour.to_s.rjust(3)}] Mode: #{stats['behavior_mode'].ljust(10)} | pH: #{format('%.2f', ph)} | HR: #{hr.to_i} | Virus: #{vrs.to_i}%"
          end

          puts "🏁 Scenario '#{@name}' complete."
        end

        private

        def default_bootstrap_state
          # (Truncated for brevity, normally loads from local_store or creates fresh)
          {
            encrypted_state: nil,
            stats: {
              "title" => "Moko Wyvern", "display_name" => "Moko Wyvern", "behavior_mode" => "Grazing",
              "is_sleeping" => false, "alert_level" => 0.0, "current_hp" => 1000000.0, "max_hp" => 1000000.0,
              "physiology" => {
                "neural" => { "conduction_velocity" => 1.0, "synaptic_stress" => 0.0, "reflex_latency" => 0.0 },
                "cardiac" => { "pulse_rate" => 60.0, "blood_pressure_delta" => 0.0, "oxygen_saturation" => 100.0 },
                "hormones" => { "adrenaline" => 0.05, "cortisol" => 0.1, "insulin" => 0.5, "metabolic_activator" => 1.0 },
                "organ_stress" => { "neural" => 0.0, "cardiac" => 0.0, "hepatic" => 0.0, "renal" => 0.0 },
                "fibrosis" => {}, "cellular_age" => 0.0, "mitochondrial_decay" => 0.0
              },
              "metabolism" => { "glucose" => 100.0, "atp_reserves" => 1.0, "lactate_level" => 0.0, "efficiency" => 1.0 },
              "immunology" => { "leukocyte_activity" => 0.1, "antibody_vault" => {}, "efficiency" => 1.0, "antigen_load" => 0.0, "protection_factor" => 0.0 },
              "microbiome" => { "flora_diversity" => 1.0, "symbiotic_ratio" => 0.8, "endotoxin_level" => 0.0, "fermentation_rate" => 1.0, "butyrate_level" => 0.5, "serotonin_precursor" => 0.7, "neuroactive_metabolites" => { "irritability" => 0.0, "calmness" => 0.1 } },
              "infections" => {}, "infectious_burden" => 0.0,
              "skeleton" => { "stress_level" => 0.0, "fractures" => [], "integrity" => 1.0, "calcium_reserves" => 1.0 },
              "anatomy" => { "epithelial" => {"health"=>1.0, "barrier_leak"=>0.0}, "connective" => {"health"=>1.0, "elasticity"=>1.0}, "muscular" => {"health"=>1.0, "peak_power"=>1.0} },
              "epigenetics" => { "methylation" => {}, "expression_bias" => 1.0, "generation_count" => 1 },
              "germline" => { "gamete_health" => 1.0, "mutagenic_pressure" => 0.0, "genetic_stability" => 1.0 },
              "chrono" => { "internal_hour" => 8.0, "melatonin_level" => 0.0, "cycle_type" => "diurnal", "alertness" => 1.0, "sleep_pressure" => 0.0 },
              "homeostasis" => { "body_temp" => 38.5, "blood_ph" => 7.4, "co2_partial" => 40.0, "bicarbonate" => 24.0 },
              "environment" => { "toxins" => 0.0, "oxygen" => 50.0, "ph" => 7.4, "weather" => "clear" },
              "ecology" => { "width" => 10, "height" => 10, "oxygen" => Array.new(100, 50.0), "toxins" => Array.new(100, 0.0), "rot" => Array.new(100, 0.0) },
              "last_activity" => "unknown", "directive" => { "title" => "None", "message" => "", "level" => 0 }
            }
          }
        end
      end

      # --- Helper Classes for DSL Context ---

      class EnvironmentConfig
        def initialize
          @settings = {}
        end
        def toxins(val); @settings['toxins'] = val.to_f; end
        def oxygen(val); @settings['oxygen'] = val.to_f; end
        def ph(val); @settings['ph'] = val.to_f; end
        def to_h; @settings; end
      end

      class StateContext
        def initialize(state)
          @stats = state[:stats]
        end

        def has_fever?
          @stats['homeostasis']['body_temp'] > 39.5
        end

        def is_acidotic?
          @stats['homeostasis']['blood_ph'] < 7.2
        end

        def viral_load(id)
          @stats['infections'][id] || 0.0
        end

        def behavior
          @stats['behavior_mode']
        end
      end

      class ActionsQueue
        def initialize(state)
          @state = state
        end

        def medicate!
          puts "    💊 ACTION: Administered broad-spectrum antibiotics."
          @state[:stats]['infections'].keys.each do |k|
            @state[:stats]['infections'][k] = 0.0
          end
          # Destroy gut flora as side effect
          @state[:stats]['microbiome']['flora_diversity'] = 0.0
        end

        def inject_adrenaline!
          puts "    ⚡ ACTION: Injected EpiPen."
          @state[:stats]['physiology']['hormones']['adrenaline'] = 1.0
        end

        def apply!
          # Handled immediately in this simple version
        end
      end
    end
  end
end
