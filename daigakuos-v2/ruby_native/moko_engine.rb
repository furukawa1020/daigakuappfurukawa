# ruby_native/moko_engine.rb
require 'json'
require_relative 'core/combat_engine'
require_relative 'core/ecosystem'
require_relative 'core/monster_brain'
require_relative 'core/alchemist'
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
  MonsterBrain.tick(state[:raid], elapsed_hours, state[:history] || [], state[:environment])
  
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
  when 'combine_items'
    item_a = request[:item_a]
    item_b = request[:item_b]
    result = Alchemist.combine(item_a, item_b)
    
    if result[:success]
      # Update user inventory (logic simplified for brevity)
      state[:user][:inventory] ||= {}
      state[:user][:inventory][item_a] -= 1
      state[:user][:inventory][item_b] -= 1
      state[:user][:inventory][result[:item]] = (state[:user][:inventory][result[:item]] || 0) + 1
      LocalStore.save_state(state)
    end
    result
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
