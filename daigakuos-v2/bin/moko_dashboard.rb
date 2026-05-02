#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative '../ruby_native/core/rust_bridge'

# Ensure the kernel is built
unless Moko::Bio::RustBridge.active?
  puts "⚠️  [ERROR] Rust Kernel is not active. Please run 'cargo build --release' in rust_core/"
  exit 1
end

# Default bootstrapping state
raid_state = {
  encrypted_state: nil,
  stats: {
    "title" => "Moko Wyvern",
    "display_name" => "Moko Wyvern",
    "behavior_mode" => "Grazing",
    "is_sleeping" => false,
    "alert_level" => 0.0,
    "current_hp" => 1000000.0,
    "max_hp" => 1000000.0,
    "physiology" => {
      "neural" => { "conduction_velocity" => 1.0, "synaptic_stress" => 0.0, "reflex_latency" => 0.0 },
      "cardiac" => { "pulse_rate" => 60.0, "blood_pressure_delta" => 0.0, "oxygen_saturation" => 100.0 },
      "hormones" => { "adrenaline" => 0.05, "cortisol" => 0.1, "insulin" => 0.5, "metabolic_activator" => 1.0 },
      "organ_stress" => { "neural" => 0.0, "cardiac" => 0.0, "hepatic" => 0.0, "renal" => 0.0 },
      "fibrosis" => {},
      "cellular_age" => 0.0,
      "mitochondrial_decay" => 0.0
    },
    "metabolism" => { "glucose" => 100.0, "atp_reserves" => 1.0, "lactate_level" => 0.0, "efficiency" => 1.0 },
    "immunology" => { "leukocyte_activity" => 0.1, "antibody_vault" => {}, "efficiency" => 1.0, "antigen_load" => 0.0, "protection_factor" => 0.0 },
    "microbiome" => { "flora_diversity" => 1.0, "symbiotic_ratio" => 0.8, "endotoxin_level" => 0.0, "fermentation_rate" => 1.0, "butyrate_level" => 0.5, "serotonin_precursor" => 0.7, "neuroactive_metabolites" => { "irritability" => 0.0, "calmness" => 0.1 } },
    "infections" => {},
    "infectious_burden" => 0.0,
    "skeleton" => { "stress_level" => 0.0, "fractures" => [], "integrity" => 1.0, "calcium_reserves" => 1.0 },
    "anatomy" => { "epithelial" => {"health"=>1.0, "barrier_leak"=>0.0}, "connective" => {"health"=>1.0, "elasticity"=>1.0}, "muscular" => {"health"=>1.0, "peak_power"=>1.0} },
    "epigenetics" => { "methylation" => {}, "expression_bias" => 1.0, "generation_count" => 1 },
    "germline" => { "gamete_health" => 1.0, "mutagenic_pressure" => 0.0, "genetic_stability" => 1.0 },
    "chrono" => { "internal_hour" => 8.0, "melatonin_level" => 0.0, "cycle_type" => "diurnal", "alertness" => 1.0, "sleep_pressure" => 0.0 },
    "homeostasis" => { "body_temp" => 38.5, "blood_ph" => 7.4, "co2_partial" => 40.0, "bicarbonate" => 24.0 },
    "environment" => { "toxins" => 0.0, "oxygen" => 50.0, "ph" => 7.4, "weather" => "clear" },
    "ecology" => { "width" => 10, "height" => 10, "oxygen" => Array.new(100, 50.0), "toxins" => Array.new(100, 0.0), "rot" => Array.new(100, 0.0) },
    "last_activity" => "unknown",
    "directive" => { "title" => "None", "message" => "", "level" => 0 }
  }
}

# Add some initial stress to make the simulation interesting
raid_state[:stats]["infections"]["moko_virus_v1"] = 0.05
raid_state[:stats]["environment"]["toxins"] = 65.0
raid_state[:stats]["chrono"]["internal_hour"] = 20.0

# 🎨 ANSI Colors & UI Helpers
C_RESET = "\e[0m"
C_BOLD = "\e[1m"
C_RED = "\e[31m"
C_GREEN = "\e[32m"
C_YELLOW = "\e[33m"
C_BLUE = "\e[34m"
C_MAGENTA = "\e[35m"
C_CYAN = "\e[36m"
C_BG_RED = "\e[41;37m"

def draw_bar(val, max, width = 20, color = C_GREEN)
  fill = ((val.to_f / max) * width).round.clamp(0, width)
  empty = width - fill
  "#{color}#{'█' * fill}#{C_RESET}#{'░' * empty}"
end

def clear_screen
  print "\e[H\e[2J"
end

# ⏱️ Dashboard Loop
puts "Initializing Bio-Kernel..."
Moko::Bio::RustBridge.simulate_tick(raid_state, 0.1, 0.0) # Bootstrap

loop do
  success = Moko::Bio::RustBridge.simulate_tick(raid_state, 1.0, 0.0)
  break unless success

  stats = raid_state[:stats]
  
  clear_screen
  puts "#{C_BG_RED}#{C_BOLD}  DAIGAKU OS v2 — SOVEREIGN BIO-KERNEL DASHBOARD  #{C_RESET}\n\n"
  
  puts "  #{C_BOLD}SUBJECT:#{C_RESET} #{stats['display_name']} (Gen #{stats['epigenetics']['generation_count']})"
  puts "  #{C_BOLD}STATUS: #{C_RESET} #{stats['behavior_mode']}  |  #{stats['is_sleeping'] ? '💤 ASLEEP' : '👁️ AWAKE'}"
  puts "  #{C_BOLD}CLOCK:  #{C_RESET} #{format('%02d:00', stats['chrono']['internal_hour'] % 24)}"
  puts "-" * 60

  # 1. Vital Signs
  hr = stats['physiology']['cardiac']['pulse_rate']
  temp = stats['homeostasis']['body_temp']
  ph = stats['homeostasis']['blood_ph']
  puts "  #{C_CYAN}【バイタル (Vitals)】#{C_RESET}"
  puts "  ♥️ Heart Rate : %3d BPM  %s" % [hr, draw_bar(hr, 200, 15, hr > 120 ? C_RED : C_GREEN)]
  puts "  🌡️ Body Temp  : %4.1f °C %s" % [temp, draw_bar(temp - 35, 8, 15, temp > 39.5 ? C_RED : C_YELLOW)]
  puts "  🩸 Blood pH   : %4.2f    %s" % [ph, draw_bar((ph - 6.8)*10, 10, 15, ph < 7.3 ? C_RED : C_CYAN)]
  puts ""

  # 2. Metabolic & Circadian
  glc = stats['metabolism']['glucose']
  atp = stats['metabolism']['atp_reserves'] * 100
  mel = stats['chrono']['melatonin_level'] * 100
  slp = stats['chrono']['sleep_pressure'] * 100
  puts "  #{C_YELLOW}【代謝・概日リズム (Metabolism & Circadian)】#{C_RESET}"
  puts "  🔋 ATP Reserve : %3d%% %s" % [atp, draw_bar(atp, 100, 15, C_YELLOW)]
  puts "  🍬 Glucose     : %3d  %s" % [glc, draw_bar(glc, 150, 15, C_MAGENTA)]
  puts "  🌙 Melatonin   : %3d%% %s" % [mel, draw_bar(mel, 100, 15, C_BLUE)]
  puts "  🛏️ Sleep Press : %3d%% %s" % [slp, draw_bar(slp, 100, 15, C_MAGENTA)]
  puts ""

  # 3. Microbiome & Immune
  lps = stats['microbiome']['endotoxin_level'] * 100
  srt = stats['microbiome']['serotonin_precursor'] * 100
  vrs = (stats['infections']['moko_virus_v1'] || 0) * 100
  ab  = (stats['immunology']['antibody_vault']['moko_virus_v1'] || 0) * 100
  puts "  #{C_GREEN}【腸内環境・免疫 (Microbiome & Immunity)】#{C_RESET}"
  puts "  🦠 Viral Load : %3d%% %s" % [vrs, draw_bar(vrs, 100, 15, C_RED)]
  puts "  🛡️ Antibodies : %3d%% %s" % [ab, draw_bar(ab, 100, 15, C_CYAN)]
  puts "  ☣️ Endotoxin  : %3d%% %s" % [lps, draw_bar(lps, 100, 15, C_RED)]
  puts "  🧠 Serotonin  : %3d%% %s" % [srt, draw_bar(srt, 100, 15, C_GREEN)]
  puts "-" * 60

  sleep 0.1 # Simulate 1 hour per 0.1 seconds (fast forward)
end
