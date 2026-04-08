# ruby_native/moko_engine.rb
require 'json'
require_relative 'core/combat_engine'
require_relative 'core/ecosystem'
require_relative 'core/monster_brain'
require_relative 'storage/local_store'

# 🚀 Moko Native Engine: Zero-Latency Logic Core
STDOUT.sync = true

def simulate_chronology!(state)
  # ⏳ Calculate elapsed time since last interaction
  last_tick = state[:user][:last_tick_at] || Time.now.to_i
  elapsed_seconds = Time.now.to_i - last_tick
  elapsed_hours = elapsed_seconds / 3600.0
  
  # 🌊 Run Ecosystem Tick (Rot & Oxygen)
  Ecosystem.tick(state, elapsed_hours)
  
  # 🧬 Run Monster Bio Tick (Hunger & Alertness)
  MonsterBrain.tick(state[:raid], elapsed_hours, state[:history] || [])
  
  # ⚖️ Apply Metabolic Effects
  Ecosystem.apply_metabolic_effects(state[:user], state[:environment])
  
  state[:user][:last_tick_at] = Time.now.to_i
end

def process_command(line)
  request = JSON.parse(line, symbolize_names: true) rescue nil
  return { error: 'Invalid JSON' } unless request

  state = LocalStore.load_state
  
  # ⏳ Run chronology simulation first
  simulate_chronology!(state)
  
  case request[:command]
  when 'get_status'
    state
  when 'process_damage'
    # ⚖️ Dynamic Combat Calculation
    duration = request[:duration] || 0
    base_damage = duration * 10
    
    result = CombatEngine.calculate_damage(
      state[:user],
      state[:raid],
      base_damage,
      state[:global_entropy]
    )
    
    # 📝 Update Local State
    state[:user].merge!(result)
    state[:raid][:current_hp] = [state[:raid][:current_hp] - result[:damage], 0].max
    LocalStore.save_state(state)
    
    result.merge(status: state[:raid][:status], boss_hp: state[:raid][:current_hp])
  when 'update_chaos'
    state[:user][:chaos_level] = request[:chaos].to_f
    LocalStore.save_state(state)
    { success: true, chaos: state[:user][:chaos_level] }
  else
    { error: 'Unknown command' }
  end
end

puts JSON.generate({ status: 'ready', message: 'Moko Native Engine Started 🐾' })

# Start listening for commands from Flutter
while line = gets
  response = process_command(line)
  puts JSON.generate(response)
end
