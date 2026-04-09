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
        metabolic_sync: 50, # Formerly neural_resonance
        status_effects: {},
        last_tick_at: Time.now.to_i
      },
      raid: {
        title: 'Moko Wyvern',
        display_name: 'Moko Wyvern',
        max_hp: 1000000, current_hp: 1000000,
        current_phase: 1, status: 'active',
        hunger: 0.0, fatigue: 0.0, alertness: 0.0,
        behavior_mode: :grazing,
        bloodline: { # Physical Inheritance
          bone_density: 1.0, 
          muscle_type: :balanced, 
          lung_capacity: 1.0,
          metabolic_rate: 1.0
        }
      },
      environment: {
        toxins: 0.0, oxygen: 50.0, weather: 'sunny'
      },
      history: [],
      toxin_load: 0.0 # Formerly global_entropy
    }
  end
end
