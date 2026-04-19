# ruby_native/moko_engine.rb
require 'json'
require_relative 'core/combat_engine'
require_relative 'core/ecosystem'
require_relative 'core/monster_brain'
require_relative 'core/microbiome'
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
require_relative 'core/germline'
require_relative 'core/orchestrator'
require_relative 'core/rust_bridge'
require_relative 'storage/local_store'

# 🚀 Moko Native Engine: Zero-Latency Logic Core
STDOUT.sync = true

def simulate_chronology!(state)
  # ⏳ Calculate elapsed time since last interaction
  last_tick = state[:user][:last_tick_at] || Time.now.to_i
  elapsed_seconds = Time.now.to_i - last_tick
  # Clamp to avoid runaway simulations after long offline gaps
  elapsed_hours = [elapsed_seconds / 3600.0, 72.0].min

  # 🌊 Ecosystem Tick (Rot & Oxygen)
  Ecosystem.tick(state, elapsed_hours)

  # 🫀 Bio-Orchestrator (Single Entry Point for all biological logic)
  dt = elapsed_seconds > 10 ? 0.1 : [elapsed_seconds, 1.0].min
  monster_type = state[:raid][:title] || 'Slime'
  state[:physics_state] ||= {}

  # Physics first (gives us physics_velocity for skeleton load)
  state[:physics] = Moko::Bio::PhysicsEngine.calculate(
    monster_type, state[:physics_state], state[:raid], dt
  )
  physics_velocity = state[:raid][:physics_velocity] || 0.0

  # 🧬 Phase 71/72/73: Rust Delegation with Ruby Fallback
  # Rust handles Physiology, Pathogens, Immunology, and the Sovereign Brain (BehaviorMode/Title)
  rust_success = Moko::Bio::RustBridge.simulate_tick(state[:raid], elapsed_hours, physics_velocity)
  
  unless rust_success
    # 🧪 Fallback to pure-Ruby orchestration for physical logic
    Moko::Bio::Orchestrator.tick(state[:raid], state[:environment], elapsed_hours, physics_velocity)
    # 🧠 Fallback to pure-Ruby brain logic
    Moko::Bio::BehavioralEcologist.update_behavior!(state[:raid], state[:environment])
  end

  # 🩸 Apply Phenotypic Biological Modifiers (Common logic)
  Moko::Bio::BloodlineEngine.apply_biology(state[:raid], state[:raid])

  state[:user][:last_tick_at] = Time.now.to_i
end

def process_command(line)
  request = JSON.parse(line, symbolize_names: true) rescue nil
  return { error: 'Invalid JSON' } unless request

  state = LocalStore.load_state

  # ⏳ Run chronology simulation first (always safe)
  begin
    simulate_chronology!(state)
  rescue => e
    STDERR.puts "[MOKO ENGINE CRITICAL] simulate_chronology! failed: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
  end

  case request[:command]
  when 'get_status'
    state[:field_notes] = begin
      Moko::Bio::FieldObserver.generate_report(state)
    rescue => e
      "【観測エラー】#{e.message}"
    end
    state

  when 'process_damage'
    duration    = request[:duration] || 0
    base_damage = duration * 10
    result = CombatEngine.calculate_damage(
      state[:user], state[:raid], base_damage, state[:toxin_load]
    )
    state[:user].merge!(result)
    state[:raid][:current_hp] = [state[:raid][:current_hp] - result[:damage], 0].max
    LocalStore.save_state(state)
    result.merge(status: state[:raid][:status], boss_hp: state[:raid][:current_hp])

  when 'update_chaos'
    state[:user][:chaos_level] = request[:chaos].to_f
    LocalStore.save_state(state)
    { success: true, chaos: state[:user][:chaos_level] }

  when 'generate_field_notes'
    notes = begin
      Moko::Bio::FieldObserver.generate_report(state)
    rescue => e
      "【観測エラー】#{e.message}"
    end
    { success: true, notes: notes }

  when 'combine_items'
    item_a = request[:item_a]
    item_b = request[:item_b]
    result = Alchemist.combine(item_a, item_b)
    if result[:success]
      state[:user][:inventory] ||= {}
      state[:user][:inventory][item_a] = [(state[:user][:inventory][item_a] || 1) - 1, 0].max
      state[:user][:inventory][item_b] = [(state[:user][:inventory][item_b] || 1) - 1, 0].max
      state[:user][:inventory][result[:item]] = (state[:user][:inventory][result[:item]] || 0) + 1
      LocalStore.save_state(state)
    end
    result

  when 'use_item'
    item = request[:item]
    mic = state[:raid][:microbiome]
    
    case item
    when 'probiotic_brew'
      mic[:flora_diversity] = [mic[:flora_diversity] + 0.3, 1.0].min
      mic[:symbiotic_ratio] = [mic[:symbiotic_ratio] + 0.2, 1.0].min
      LocalStore.save_state(state)
      { success: true, message: "微生物叢の整合性が改善しました🐾" }
    when 'prebiotic_fiber'
      mic[:endotoxin_level] = [mic[:endotoxin_level] - 0.3, 0.0].max
      LocalStore.save_state(state)
      { success: true, message: "腸内毒素が中和されました🍵" }
    else
      { success: false, message: "使用できないアイテムです" }
    end

  when 'rebirth'
    Moko::Bio::BloodlineEngine.rebirth!(state[:raid])
    LocalStore.save_state(state)
    { success: true, generation: state[:raid][:epigenetics][:generation_count] }

  else
    { error: "Unknown command: #{request[:command]}" }
  end
end

puts JSON.generate({ status: 'ready', message: 'Moko Native Engine Started 🐾' })

# Start listening for commands from Flutter
while (line = gets)
  line.strip!
  next if line.empty?
  response = process_command(line)
  puts JSON.generate(response)
end
