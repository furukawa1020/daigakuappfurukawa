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
        order_level: 0.0, chaos_level: 0.0, neural_resonance: 50,
        status_effects: {}
      },
      raid: {
        title: 'Moko Wyvern',
        max_hp: 1000000, current_hp: 1000000,
        current_phase: 1, status: 'active'
      },
      global_entropy: 0.0
    }
  end
end
