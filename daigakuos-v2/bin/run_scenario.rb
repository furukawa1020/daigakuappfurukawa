#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../ruby_native/dsl/scenario'

# Define a scenario using our new Ruby DSL
pandemic = Moko::Bio::DSL::Scenario.define "The Moko Pandemic" do
  # 1. Setup Environment
  environment do
    toxins 45.0
    ph 6.8 # slightly acidic air?
  end

  # 2. Setup Conditions
  inject_virus "moko_virus_v1", initial_load: 0.15

  # 3. Define reactive rules (Ruby Blocks evaluated on every tick)
  on_condition do |actions|
    if has_fever? && behavior == "Lethargic"
      puts "    ⚠️ Trigger: Fever detected! Administering antibiotics..."
      actions.medicate!
    end

    if viral_load("moko_virus_v1") > 0.6
      puts "    ⚠️ Trigger: Critical Viral Load! Adrenaline spike injected!"
      actions.inject_adrenaline!
    end
  end
end

puts "================================================="
puts "🧬 DaigakuOS Bio-Kernel DSL Execution"
puts "================================================="

# Run the scenario for 48 virtual hours
pandemic.run!(48)
