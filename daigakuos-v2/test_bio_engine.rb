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

puts "🔬 Testing Moko::Bio: THE GENETIC & IMMUNOLOGICAL FRONTIER..."

# Debug: Verify class presence
puts "🧬 GeneticsEngine Methods: #{Moko::Bio::GeneticsEngine.methods(false).grep(/tick/)}"

begin
  # 1. Initialize Ultimate State
  raid_state = { 
    title: "Test Wyvern", 
    display_name: "Test Wyvern",
    bloodline: { bone_density: 1.1, muscle_type: :twitch, metabolic_rate: 1.2 }, 
    environment: { toxins: 40, oxygen: 80 } 
  }
  
  Moko::Bio::PhysiologyEngine.initialize_physiology(raid_state)
  Moko::Bio::MetabolismEngine.initialize_metabolism(raid_state)
  Moko::Bio::HomeostasisEngine.initialize_homeostasis(raid_state)
  Moko::Bio::ImmunologyEngine.initialize_immunology(raid_state)
  Moko::Bio::GeneticsEngine.initialize_genetics(raid_state)
  
  dt = 1.0 # Hours
  
  puts "\n1. Simulating Deep Adaptation (1 Hour Exposure)..."
  Moko::Bio::PhysiologyEngine.tick(raid_state, raid_state[:environment], dt)
  Moko::Bio::MetabolismEngine.tick(raid_state, dt)
  Moko::Bio::HomeostasisEngine.tick(raid_state, dt)
  Moko::Bio::ImmunologyEngine.tick(raid_state, raid_state[:environment], dt)
  Moko::Bio::GeneticsEngine.tick(raid_state, dt)
  
  puts "   - Immune Activation: #{(raid_state[:immunology][:leukocyte_activity] * 100).to_i}%"
  puts "   - Antibody Titer: #{raid_state[:immunology][:antibody_titer].round(4)}"
  puts "   - DNA Methylation (Total): #{raid_state[:epigenetics][:methylation].values.sum.round(6)}"
  
  puts "\n2. Testing Epigenetic Phenotype Expression..."
  Moko::Bio::GeneticsEngine.tick(raid_state, 5.0) 
  pheno = raid_state[:phenotype]
  puts "   - Expressed Metabolic Rate: #{pheno[:metabolic_rate]}"
  
  puts "\n3. Generating Ultimate Field Notes..."
  state = { raid: raid_state, environment: raid_state[:environment], user: { metabolic_sync: 80, hp: 100 } }
  # Ensure Homeostatic modifiers are present for observer
  state[:homeostatic_modifiers] = raid_state[:homeostatic_modifiers]
  
  report = Moko::Bio::FieldObserver.generate_report(state)
  puts report
  
  puts "\n✅ ULTIMATE BIOLOGICAL FRONTIER VERIFIED."
rescue => e
  puts "\n❌ TEST FAILED: [#{e.class}] #{e.message}"
  puts e.backtrace[0..5].join("\n")
  exit 1
end
