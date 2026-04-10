# test_bio_engine.rb
require 'json'
require_relative 'ruby_native/core/bio_physics'
require_relative 'ruby_native/core/bloodline_engine'
require_relative 'ruby_native/core/field_observer'

puts "🔬 Testing Moko::Bio Namespace Resolution..."

begin
  bloodline = { bone_density: 1.2, muscle_type: :twitch, lung_capacity: 1.1 }
  state = { x: 0.0, v: 0.0 }
  dt = 0.01
  
  puts "1. Testing PhysicsEngine (Slime)..."
  physics = Moko::Bio::PhysicsEngine.calculate("Slime", state, bloodline, dt)
  puts "   Result: #{physics.inspect}"
  
  puts "2. Testing PhysicsEngine (Dragon)..."
  physics_d = Moko::Bio::PhysicsEngine.calculate("Dragon", { phase: 0.0 }, bloodline, dt)
  puts "   Result: #{physics_d.inspect}"
  
  puts "3. Testing FieldObserver Reporting..."
  mock_state = { 
    environment: { toxins: 10, oxygen: 85, weather: 'sunny' },
    raid: { display_name: "Test Wyvern", bloodline: bloodline },
    user: { hp: 100, metabolic_sync: 80 },
    toxin_load: 0.1
  }
  report = Moko::Bio::FieldObserver.generate_report(mock_state)
  puts "   Report Preview:\n#{report[0..100]}..."
  
  puts "\n✅ ALL BIO-SYSTEMS STABILIZED."
rescue => e
  puts "\n❌ TEST FAILED: #{e.message}"
  puts e.backtrace[0..5].join("\n")
  exit 1
end
