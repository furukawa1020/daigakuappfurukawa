# ruby_native/moko_engine.rb
require 'json'
require_relative 'core/combat_engine'
require_relative 'core/ecosystem'
require_relative 'core/monster_brain'
require_relative 'core/bio_physics'
require_relative 'core/alchemist'
require_relative 'core/bloodline_engine'
require_relative 'core/field_observer'
require_relative 'core/physiology'
require_relative 'core/metabolism'
require_relative 'core/homeostasis'
require_relative 'core/immunology'
require_relative 'core/genetics'
require_relative 'core/sensory'
require_relative 'core/chronobiology'
require_relative 'core/skeleton'
require_relative 'core/anatomy'
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
  
  # 🫀 1. Physiology, Metabolism & Homeostasis (Phase 61/62)
  Moko::Bio::PhysiologyEngine.initialize_physiology(state[:raid])
  Moko::Bio::MetabolismEngine.initialize_metabolism(state[:raid])
  Moko::Bio::HomeostasisEngine.initialize_homeostasis(state[:raid])
  Moko::Bio::ImmunologyEngine.initialize_immunology(state[:raid])
  Moko::Bio::GeneticsEngine.initialize_genetics(state[:raid])
  Moko::Bio::SensoryEngine.initialize_sensory(state[:raid])
  Moko::Bio::ChronobiologyEngine.initialize_chrono(state[:raid])
  Moko::Bio::SkeletonEngine.initialize_skeleton(state[:raid])
  Moko::Bio::AnatomyEngine.initialize_anatomy(state[:raid])
  
  Moko::Bio::PhysiologyEngine.tick(state[:raid], state[:environment], elapsed_hours)
  Moko::Bio::MetabolismEngine.tick(state[:raid], elapsed_hours)
  Moko::Bio::HomeostasisEngine.tick(state[:raid], elapsed_hours)
  Moko::Bio::ImmunologyEngine.tick(state[:raid], state[:environment], elapsed_hours)
  Moko::Bio::GeneticsEngine.tick(state[:raid], elapsed_hours)
  Moko::Bio::SensoryEngine.tick(state[:raid], state[:environment], elapsed_hours)
  Moko::Bio::ChronobiologyEngine.tick(state[:raid], elapsed_hours)
  Moko::Bio::SkeletonEngine.tick(state[:raid], state[:raid][:physics_velocity], elapsed_hours)
  Moko::Bio::AnatomyEngine.tick(state[:raid], elapsed_hours)
  
  # 🐉 Monster AI Evaluation (Biological Ecologist)
  monster_action = Moko::Bio::BehavioralEcologist.decide_action(state[:raid], state[:toxin_load])
  
  # 🩸 2. Apply Phenotypic Biological Modifiers (Phase 63)
  # Use the expressed Phenotype instead of the raw Bloodline
  Moko::Bio::BloodlineEngine.apply_biology(state[:raid], state[:raid]) 
  
  # 🧠 3. Ecological Decision Engine
  Moko::Bio::BehavioralEcologist.update_behavior!(state[:raid], state[:environment])
  
  # 🧪 Run Bio-Physics Engine Tick
  # We use a delta-time of ~0.1s for simulation logic if not specified
  dt = elapsed_seconds > 10 ? 0.1 : [elapsed_seconds, 1.0].min 
  monster_type = state[:raid][:title] || "Slime"
  
  state[:physics_state] ||= {}
  state[:physics] = Moko::Bio::PhysicsEngine.calculate(monster_type, state[:physics_state], state[:raid], dt)
  
  state[:user][:last_tick_at] = Time.now.to_i
end

def generate_field_notes(state)
  # Delegate to the specialized Naturalist module
  Moko::Bio::FieldObserver.generate_report(state)
end

def process_command(line)
  request = JSON.parse(line, symbolize_names: true) rescue nil
  return { error: 'Invalid JSON' } unless request

  state = LocalStore.load_state
  
  # ⏳ Run chronology simulation first
  simulate_chronology!(state)
  
  case request[:command]
  when 'get_status'
    # Inject live biological notes into every status refresh for HUD sync
    state[:field_notes] = Moko::Bio::FieldObserver.generate_report(state)
    state
  when 'process_damage'
    # ⚖️ Dynamic Combat Calculation
    duration = request[:duration] || 0
    base_damage = duration * 10
    
    result = CombatEngine.calculate_damage(
      state[:user],
      state[:raid],
      base_damage,
      state[:toxin_load]
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
  when 'generate_field_notes'
    { success: true, notes: generate_field_notes(state) }
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
