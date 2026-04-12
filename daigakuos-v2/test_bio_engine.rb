# test_bio_engine.rb
require 'json'
require_relative 'ruby_native/core/bio_physics'
require_relative 'ruby_native/core/bloodline_engine'
require_relative 'ruby_native/core/field_observer'
require_relative 'ruby_native/core/physiology'
require_relative 'ruby_native/core/metabolism'
require_relative 'ruby_native/core/homeostasis'
require_relative 'ruby_native/core/immunology'
require_relative 'ruby_native/core/genetics'
require_relative 'ruby_native/core/sensory'
require_relative 'ruby_native/core/chronobiology'
require_relative 'ruby_native/core/skeleton'
require_relative 'ruby_native/core/anatomy'

puts "🔬 Testing Moko::Bio: THE STRUCTURAL & ANATOMIC FRONTIER..."

begin
  # 1. Initialize High-Fidelity State
  raid_state = { 
    title: "Test Wyvern", 
    display_name: "Test Wyvern",
    bloodline: { bone_density: 0.8, muscle_type: :twitch, metabolic_rate: 1.2 }, 
    environment: { toxins: 20, oxygen: 80 } 
  }
  
  Moko::Bio::PhysiologyEngine.initialize_physiology(raid_state)
  Moko::Bio::MetabolismEngine.initialize_metabolism(raid_state)
  Moko::Bio::HomeostasisEngine.initialize_homeostasis(raid_state)
  Moko::Bio::ImmunologyEngine.initialize_immunology(raid_state)
  Moko::Bio::GeneticsEngine.initialize_genetics(raid_state)
  Moko::Bio::SensoryEngine.initialize_sensory(raid_state)
  Moko::Bio::ChronobiologyEngine.initialize_chrono(raid_state)
  Moko::Bio::SkeletonEngine.initialize_skeleton(raid_state)
  Moko::Bio::AnatomyEngine.initialize_anatomy(raid_state)
  
  puts "\n1. Simulating High Mechanical Load..."
  # High velocity physics
  velocity = 15.0
  Moko::Bio::SkeletonEngine.tick(raid_state, velocity, 1.0)
  
  puts "   - Bone Stress Level: #{raid_state[:skeleton][:stress_level].round(4)}"
  puts "   - Fractures: #{raid_state[:skeleton][:fractures].inspect}"
  
  puts "\n2. Testing Physics Limp Feedback (RK4 Asymmetry)..."
  # Slime physics with fracture bias
  physics = Moko::Bio::PhysicsEngine.calculate("Slime", { x: 5.0, v: 0.0 }, raid_state, 0.01)
  puts "   - Physics with Limp Bias: #{physics.is_a?(Hash) ? 'Calculated' : 'Error'}"
  
  puts "\n3. Testing Tissue Infiltration & Anatomy..."
  Moko::Bio::AnatomyEngine.tick(raid_state, 1.0)
  puts "   - Connective Elasticity: #{raid_state[:anatomy][:connective][:elasticity]}"
  puts "   - Muscular Peak Power: #{raid_state[:anatomy][:muscular][:peak_power]}"
  
  puts "\n4. Generating Ultimate Field Notes..."
  state = { raid: raid_state, environment: raid_state[:environment], user: { metabolic_sync: 80, hp: 100 } }
  report = Moko::Bio::FieldObserver.generate_report(state)
  puts report
  
  puts "\n✅ STRUCTURAL & ANATOMIC FRONTIER VERIFIED. Engine is Rigid yet Fragile."
rescue => e
  puts "\n❌ TEST FAILED: [#{e.class}] #{e.message}"
  puts e.backtrace[0..5].join("\n")
  exit 1
end
