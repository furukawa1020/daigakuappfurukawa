# ruby_native/storage/local_store.rb
require 'json'
require 'fileutils'

class LocalStore
  STORAGE_FILE = 'moko_world_state.json'

  def self.save_state(data)
    File.write(STORAGE_FILE, JSON.pretty_generate(data))
  end

  def self.load_state
    if File.exist?(STORAGE_FILE)
      JSON.parse(File.read(STORAGE_FILE), symbolize_names: true) 
    else
      initial_state
    end
  end

  def self.initial_state
    {
      user: {
        hp: 100, max_hp: 100, stamina: 100, max_stamina: 100,
        streak: 0, coins: 0, role: 'dps',
        order_level: 0.0, chaos_level: 0.0,
        metabolic_sync: 50,
        status_effects: {},
        last_tick_at: Time.now.to_i
      },
      raid: {
        title: 'Moko Wyvern',
        display_name: 'Moko Wyvern',
        max_hp: 1_000_000, current_hp: 1_000_000,
        current_phase: 1, status: 'active',
        hunger: 0.0, fatigue: 0.0, alertness: 0.0,
        behavior_mode: :grazing,
        is_sleeping: false,
        physics_velocity: 0.0,
        bloodline: {
          bone_density: 1.0, muscle_type: :balanced,
          lung_capacity: 1.0, metabolic_rate: 1.0
        },
        physiology: {
          neural:      { conduction_velocity: 1.0, synaptic_stress: 0.0, reflex_latency: 0.0 },
          cardiac:     { pulse_rate: 60, blood_pressure_delta: 0.0, oxygen_saturation: 100.0 },
          hormones:    { adrenaline: 0.05, cortisol: 0.1, insulin: 0.5, metabolic_activator: 1.0 },
          organ_stress:{ neural: 0.0, cardiac: 0.0, hepatic: 0.0, renal: 0.0 },
          fibrosis:    { neural: 0.0, cardiac: 0.0, hepatic: 0.0, renal: 0.0 },
          cellular_age: 0.0,
          mitochondrial_decay: 0.0
        },
        metabolism: {
          glucose: 100.0, atp_reserves: 1.0,
          lactate_level: 0.0, efficiency: 1.0,
          last_metabolic_state: :stable
        },
        homeostatic_modifiers: {
          muscle_force: 1.0, reaction_speed: 1.0, oxygen_efficiency: 1.0
        },
        immunology: {
          leukocyte_activity: 0.1, antibody_titer: 0.0, protection_factor: 0.0
        },
        epigenetics: {
          methylation: { bone_density: 0.0, metabolic_rate: 0.0, lung_capacity: 0.0 },
          expression_bias: 1.0, generation_count: 1
        },
        phenotype: {},
        sensory: {
          chemo_sensitivity: 1.0, signal_noise_floor: 0.05,
          last_perception: { toxins: 0.0, oxygen: 50.0 }
        },
        perception: { toxins: 0.0, oxygen: 50.0 },
        chrono: {
          internal_hour: 12.0, melatonin_level: 0.1,
          cycle_type: :diurnal, alertness: 1.0
        },
        skeleton: {
          stress_level: 0.0, fractures: [], integrity: 1.0, calcium_reserves: 1.0
        },
        anatomy: {
          epithelial: { health: 1.0, barrier_leak: 0.0 },
          connective:  { health: 1.0, elasticity: 1.0 },
          muscular:    { health: 1.0, peak_power: 1.0 }
        },
        germline: {
          gamete_health: 1.0, mutagenic_pressure: 0.0, genetic_stability: 1.0
        }
      },
      environment: {
        toxins: 0.0, oxygen: 50.0, weather: 'sunny'
      },
      history: [],
      toxin_load: 0.0
    }
  end
end
