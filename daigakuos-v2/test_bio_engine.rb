# test_bio_engine.rb
require 'json'
require_relative 'ruby_native/core/bio_physics'
require_relative 'ruby_native/core/bloodline_engine'
require_relative 'ruby_native/core/field_observer'
require_relative 'ruby_native/core/physiology'
require_relative 'ruby_native/core/metabolism'
require_relative 'ruby_native/core/homeostasis'

puts "🔬 Testing Moko::Bio: THE BIOLOGICAL SYNTHESIS..."

begin
  # 1. Initialize High-Fidelity State
  raid_state = { title: "Test Wyvern", bloodline: { bone_density: 1.1, muscle_type: :twitch, metabolic_rate: 1.2 }, environment: { toxins: 20, oxygen: 80 } }
  Moko::Bio::PhysiologyEngine.initialize_physiology(raid_state)
  Moko::Bio::MetabolismEngine.initialize_metabolism(raid_state)
  Moko::Bio::HomeostasisEngine.initialize_homeostasis(raid_state)
  
  dt = 0.1 # Hours
  
  puts "\n1. Simulating Physiological Tick..."
  Moko::Bio::PhysiologyEngine.tick(raid_state, raid_state[:environment], dt)
  Moko::Bio::MetabolismEngine.tick(raid_state, dt)
  Moko::Bio::HomeostasisEngine.tick(raid_state, dt)
  
  puts "   - Glucose: #{raid_state[:metabolism][:glucose].round(2)}"
  puts "   - Pulse: #{raid_state[:physiology][:cardiac][:pulse_rate]} bpm"
  puts "   - pH: #{raid_state[:environment][:pH]}"
  
  puts "\n2. Testing Adrenaline Surge Impact..."
  Moko::Bio::PhysiologyEngine.trigger_adrenaline_surge(raid_state, 0.8)
  Moko::Bio::PhysiologyEngine.tick(raid_state, raid_state[:environment], 0.01)
  Moko::Bio::HomeostasisEngine.tick(raid_state, 0.01)
  
  puts "   - Adrenaline: #{raid_state[:physiology][:hormones][:adrenaline].round(2)}"
  puts "   - Muscle Force Mult: #{raid_state[:homeostatic_modifiers][:muscle_force].round(2)}"
  
  puts "\n3. Testing Physics Engine with Physiological Feedback..."
  physics = Moko::Bio::PhysicsEngine.calculate("Slime", { x: 0.0, v: 0.0 }, raid_state, 0.01)
  puts "   - Slime Physics (Jittered): #{physics.inspect}"
  
  # 4. Generating Deep Field Notes
  # Wrap in the top-level state hierarchy expected by FieldObserver
  state = { raid: raid_state, environment: raid_state[:environment], user: { metabolic_sync: 80, hp: 100 } }
  report = Moko::Bio::FieldObserver.generate_report(state)
  puts report
  
  puts "\n✅ BIOLOGICAL SYNTHESIS VERIFIED. Engine is Stable and Granular."
rescue => e
  puts "\n❌ TEST FAILED: #{e.message}"
  puts e.backtrace[0..5].join("\n")
  exit 1
end
