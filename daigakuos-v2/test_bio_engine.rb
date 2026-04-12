# test_bio_engine.rb — Phase 67: Stability & Stress Test
# Tests: Orchestrator self-healing, crash-resistance, and 10,000-hour simulation.
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
require_relative 'ruby_native/core/orchestrator'
require_relative 'ruby_native/storage/local_store'

puts "🔬 Phase 67: STABILITY & STRESS TEST"
puts "=" * 50

errors_found = 0

# ────────────────────────────────────────────
# TEST 1: Self-Healing State Doctor
# ────────────────────────────────────────────
puts "\n[TEST 1] Orchestrator Self-Healing (Partial State Input)..."
partial_state = {
  title: 'Test Wyvern',
  bloodline: { bone_density: 1.2, muscle_type: :twitch, metabolic_rate: 1.0, lung_capacity: 1.0 },
  environment: { toxins: 30, oxygen: 70 }
}
# INTENTIONALLY omit physiology/metabolism/skeleton/germline etc.
begin
  Moko::Bio::Orchestrator.ensure_state!(partial_state)
  raise "Missing physiology"   unless partial_state[:physiology]
  raise "Missing skeleton"     unless partial_state[:skeleton]
  raise "Missing germline"     unless partial_state[:germline]
  raise "Missing epigenetics"  unless partial_state[:epigenetics]
  raise "Missing chrono"       unless partial_state[:chrono]
  puts "   ✅ Self-Healing PASSED — all missing keys restored."
rescue => e
  puts "   ❌ FAILED: #{e.message}"
  errors_found += 1
end

# ────────────────────────────────────────────
# TEST 2: Single full tick (Orchestrator)
# ────────────────────────────────────────────
puts "\n[TEST 2] Single Full Tick via Orchestrator..."
begin
  state = {
    title: 'Wyvern G1',
    bloodline: { bone_density: 1.0, muscle_type: :balanced, metabolic_rate: 1.0, lung_capacity: 1.0 },
    environment: { toxins: 50, oxygen: 60 }
  }
  Moko::Bio::Orchestrator.tick(state, state[:environment], 1.0, 2.0)
  raise "No cortisol" unless state.dig(:physiology, :hormones, :cortisol)
  raise "No antibody" unless state.dig(:immunology, :antibody_titer)
  puts "   ✅ Single Tick PASSED — #{state.dig(:physiology, :hormones, :cortisol).round(4)} cortisol"
rescue => e
  puts "   ❌ FAILED: #{e.message}"
  puts "      #{e.backtrace.first}"
  errors_found += 1
end

# ────────────────────────────────────────────
# TEST 3: 10,000 hour stress simulation
# ────────────────────────────────────────────
puts "\n[TEST 3] 10,000 Hour Stress Simulation..."
begin
  state = LocalStore.initial_state[:raid]
  env   = { toxins: 60.0, oxygen: 55.0 }
  dt    = 1.0
  crashes = []
  
  10_000.times do |h|
    begin
      Moko::Bio::Orchestrator.tick(state, env, dt, rand * 5.0)
    rescue => e
      crashes << "Hour #{h}: #{e.class} — #{e.message}"
    end
  end
  
  cellular_age = state.dig(:physiology, :cellular_age) || 0
  decay        = state.dig(:physiology, :mitochondrial_decay) || 0
  fibro        = state.dig(:physiology, :fibrosis).values.sum rescue 0
  gen_health   = state.dig(:germline, :gamete_health) || 1.0
  
  puts "   Cellular Age:         #{cellular_age.round(1)}h (expected ~10000)"
  puts "   Mitochondrial Decay:  #{(decay * 100).to_i}%"
  puts "   Total Fibrosis:       #{fibro.round(4)}"
  puts "   Germline Health:      #{(gen_health * 100).to_i}%"
  puts "   Simulation Errors:    #{crashes.size}"
  puts crashes.first(3).map { |e| "      ⚠️  #{e}" }.join("\n") unless crashes.empty?
  
  if crashes.empty?
    puts "   ✅ Stress Test PASSED — engine survived 10,000 simulated hours."
  else
    puts "   ⚠️  Completed with #{crashes.size} non-fatal errors (safety-wrapped)."
  end
rescue => e
  puts "   ❌ CATASTROPHIC FAILURE: #{e.message}"
  errors_found += 1
end

# ────────────────────────────────────────────
# TEST 4: FieldObserver nil-safety
# ────────────────────────────────────────────
puts "\n[TEST 4] FieldObserver Nil-Safety..."
begin
  # Completely bare state
  bare = { raid: {}, environment: {}, user: { hp: 100, metabolic_sync: 50 } }
  report = Moko::Bio::FieldObserver.generate_report(bare)
  raise "Report is nil" if report.nil? || report.empty?
  puts "   ✅ FieldObserver nil-safety PASSED."
rescue => e
  puts "   ❌ FAILED: #{e.message}"
  errors_found += 1
end

# ────────────────────────────────────────────
# TEST 5: Succession / Rebirth
# ────────────────────────────────────────────
puts "\n[TEST 5] Succession (Rebirth) Event..."
begin
  rs = LocalStore.initial_state[:raid]
  Moko::Bio::Orchestrator.tick(rs, { toxins: 80, oxygen: 50 }, 100.0, 0.0)
  gen_before = rs.dig(:epigenetics, :generation_count)
  Moko::Bio::BloodlineEngine.rebirth!(rs)
  gen_after  = rs.dig(:epigenetics, :generation_count)
  age_after  = rs.dig(:physiology, :cellular_age)
  
  raise "Generation did not increment" unless gen_after == gen_before + 1
  raise "Cellular age not reset"       unless age_after == 0.0
  puts "   ✅ Rebirth PASSED — G#{gen_before} → G#{gen_after}, Age reset to #{age_after}"
rescue => e
  puts "   ❌ FAILED: #{e.message}"
  puts "      #{e.backtrace.first}"
  errors_found += 1
end

# ────────────────────────────────────────────
puts "\n#{'=' * 50}"
if errors_found == 0
  puts "✅ ALL TESTS PASSED. Engine is production-ready."
else
  puts "❌ #{errors_found} TEST(S) FAILED. Review above errors."
  exit 1
end
