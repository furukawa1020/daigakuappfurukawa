# frozen_string_literal: true
require 'fileutils'
require 'json'
require_relative '../ruby_native/core/rust_bridge'
require_relative '../ruby_native/storage/local_store'

puts "🚀 DaigakuOS v2: Sovereignty Setup"
puts "=" * 40

# 1. Rust Build
puts "\n[1/3] Building Rust Bio-Kernel (Release Mode)..."
Dir.chdir('rust_core') do
  system('cargo build --release')
end

unless Moko::Bio::RustBridge.active?
  puts "❌ ERROR: Rust binary not found at #{Moko::Bio::RustBridge::RUST_BINARY}"
  exit 1
end
puts "✅ Rust Kernel built successfully."

# 2. Vault Bootstrap (Phase 77 Security)
puts "\n[2/3] Sealing Simulation State (Vault Bootstrap)..."
state = LocalStore.load_state
if state[:raid][:encrypted_state]
  puts "   ⚠️  State is already sealed. Skipping bootstrap."
else
  # Using the 'bootstrap' branch logic in RustBridge
  success = Moko::Bio::RustBridge.simulate_tick(state[:raid], 0.0, 0.0)
  if success
    LocalStore.save_state(state)
    puts "✅ Vault initialized and state sealed with AES-256-GCM."
  else
    puts "❌ ERROR: Bootstrap failed. Check rust_core logs."
    exit 1
  end
end

# 3. Final Verification
puts "\n[3/3] Final Runnability Check..."
if File.exist?('test_bio_engine.rb')
  puts "✅ Environment is READY."
  puts "\nTo run the tests:  ruby test_bio_engine.rb"
  puts "To run the engine: ruby ruby_native/moko_engine.rb"
end

puts "\n#{'=' * 40}"
puts "Sovereignty Edition Setup Complete 🐾"
