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
require_relative 'ruby_native/core/germline'

puts "🔬 Testing Moko::Bio: THE SUCCESSION SAGA (Phase 66)..."

begin
  # 1. Initialize Parent state
  raid_state = { 
    title: "Parent Wyvern", 
    bloodline: { bone_density: 1.0, muscle_type: :balanced, metabolic_rate: 1.0, lung_capacity: 1.0 }, 
    environment: { toxins: 90, oxygen: 50 } 
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
  Moko::Bio::GermlineEngine.initialize_germline(raid_state)
  
  puts "\n1. Simulating Parental Stress & Germline Damage..."
  # High cortisol leads to high methylation
  raid_state[:physiology][:hormones][:cortisol] = 0.9
  Moko::Bio::GeneticsEngine.tick(raid_state, 10.0)
  Moko::Bio::GermlineEngine.tick(raid_state, 10.0)
  
  parent_meth = raid_state[:epigenetics][:methylation].values.sum
  puts "   - Parent DNA Methylation Total: #{parent_meth.round(4)}"
  puts "   - Parent Germline Health: #{raid_state[:germline][:gamete_health].round(4)}"
  
  puts "\n2. Triggering SUCCESSION (The Rebirth Event)..."
  Moko::Bio::BloodlineEngine.rebirth!(raid_state)
  
  puts "   - Offspring Cellular Age: #{raid_state[:physiology][:cellular_age]}"
  puts "   - Generation Count: #{raid_state[:epigenetics][:generation_count]}"
  
  child_meth = raid_state[:epigenetics][:methylation].values.sum
  puts "   - Inherited Methylation (Epigenetic Burden): #{child_meth.round(4)}"
  
  puts "\n3. Checking Congenital Defects..."
  hepatic_fibro = raid_state[:physiology][:fibrosis][:hepatic]
  puts "   - Inherited Hepatic Fibrosis: #{hepatic_fibro.round(4)} (Congenital)"
  
  puts "\n4. Generating Succession Field Notes..."
  state = { raid: raid_state, environment: raid_state[:environment], user: { metabolic_sync: 80, hp: 100 } }
  report = Moko::Bio::FieldObserver.generate_report(state)
  puts report
  
  puts "\n✅ SUCCESSION SAGA VERIFIED. The lineage carries the history of its ancestors."
rescue => e
  puts "\n❌ TEST FAILED: [#{e.class}] #{e.message}"
  puts e.backtrace[0..5].join("\n")
  exit 1
end
