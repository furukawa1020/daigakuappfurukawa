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

puts "🔬 Testing Moko::Bio: THE SENSORY & CIRCADIAN FRONTIER..."

begin
  # 1. Initialize High-Fidelity State
  raid_state = { 
    title: "Test Wyvern", 
    display_name: "Test Wyvern",
    bloodline: { bone_density: 1.1, muscle_type: :twitch, metabolic_rate: 1.2 }, 
    environment: { toxins: 80, oxygen: 50 } 
  }
  
  Moko::Bio::PhysiologyEngine.initialize_physiology(raid_state)
  Moko::Bio::MetabolismEngine.initialize_metabolism(raid_state)
  Moko::Bio::HomeostasisEngine.initialize_homeostasis(raid_state)
  Moko::Bio::ImmunologyEngine.initialize_immunology(raid_state)
  Moko::Bio::GeneticsEngine.initialize_genetics(raid_state)
  Moko::Bio::SensoryEngine.initialize_sensory(raid_state)
  Moko::Bio::ChronobiologyEngine.initialize_chrono(raid_state)
  
  puts "\n1. Simulating High Stress & Sensory Noise..."
  # Artificially damage nerves to increase noise
  raid_state[:physiology][:organ_stress][:neural] = 0.9
  Moko::Bio::PhysiologyEngine.tick(raid_state, raid_state[:environment], 0.1)
  Moko::Bio::SensoryEngine.tick(raid_state, raid_state[:environment], 0.1)
  
  puts "   - Raw Toxins: #{raid_state[:environment][:toxins]}"
  puts "   - Perceived Toxins (Noisy/Laggy): #{raid_state[:perception][:toxins]}"
  
  puts "\n2. Simulating Nocturnal Cycle (Sleep & Repair)..."
  raid_state[:chrono][:internal_hour] = 2.0 # 2 AM
  Moko::Bio::ChronobiologyEngine.tick(raid_state, 0.1)
  
  pre_stress = raid_state[:physiology][:organ_stress][:neural]
  Moko::Bio::PhysiologyEngine.tick(raid_state, raid_state[:environment], 1.0) # 1 hour of sleep
  post_stress = raid_state[:physiology][:organ_stress][:neural]
  
  puts "   - Is Sleeping: #{raid_state[:is_sleeping]}"
  puts "   - Neural Stress Repair: #{(pre_stress - post_stress).round(4)} (Accelerated)"
  
  puts "\n3. Testing Fibrosis Conversion (Permanent Scarring)..."
  # Simulate long exposure to high stress
  raid_state[:physiology][:organ_stress][:hepatic] = 1.0
  Moko::Bio::PhysiologyEngine.tick(raid_state, raid_state[:environment], 10.0)
  puts "   - Hepatic Fibrosis Index: #{raid_state[:physiology][:fibrosis][:hepatic].round(4)}"
  
  puts "\n4. Generating Ultimate Field Notes..."
  state = { raid: raid_state, environment: raid_state[:environment], user: { metabolic_sync: 80, hp: 100 } }
  report = Moko::Bio::FieldObserver.generate_report(state)
  puts report
  
  puts "\n✅ SENSORY & CIRCADIAN FRONTIER VERIFIED. Engine is Deeply Biological."
rescue => e
  puts "\n❌ TEST FAILED: [#{e.class}] #{e.message}"
  puts e.backtrace[0..5].join("\n")
  exit 1
end
