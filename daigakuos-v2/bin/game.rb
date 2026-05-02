#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'io/console'
require_relative '../ruby_native/core/rust_bridge'

# 🎨 ANSI Colors & UI Helpers
C_RESET   = "\e[0m"
C_BOLD    = "\e[1m"
C_RED     = "\e[31m"
C_GREEN   = "\e[32m"
C_YELLOW  = "\e[33m"
C_BLUE    = "\e[34m"
C_MAGENTA = "\e[35m"
C_CYAN    = "\e[36m"
C_BG_RED  = "\e[41;37m"

def draw_bar(val, max, width = 15, color = C_GREEN)
  fill = ((val.to_f / max) * width).round.clamp(0, width)
  empty = width - fill
  "#{color}#{'█' * fill}#{C_RESET}#{'░' * empty}"
end

def clear_screen
  print "\e[H\e[2J"
end

# 🛠️ State Initialization
unless Moko::Bio::RustBridge.active?
  puts "⚠️  [ERROR] Rust Kernel is not active. Please build it first."
  exit 1
end

@state = {
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

# 🕹️ Engine Interactions
def tick_engine(hours)
  Moko::Bio::RustBridge.simulate_tick(@state, hours, 0.0)
end

def apply_action(action)
  stats = @state[:stats]
  case action
  when :eat_sugar
    stats['metabolism']['glucose'] += 50.0
    stats['physiology']['hormones']['insulin'] = 1.0
    stats['microbiome']['flora_diversity'] -= 0.05 # Sugar hurts diversity
  when :eat_fiber
    stats['metabolism']['glucose'] += 10.0
    stats['microbiome']['flora_diversity'] += 0.1 # Fiber heals diversity
  when :sleep
    stats['is_sleeping'] = true
    tick_engine(8.0) # Sleep for 8 hours
    stats['is_sleeping'] = false
    return
  when :work
    stats['physiology']['hormones']['cortisol'] += 0.3
    stats['last_activity'] = "work"
    tick_engine(2.0)
    return
  when :workout
    stats['metabolism']['lactate_level'] += 0.5
    stats['physiology']['hormones']['adrenaline'] += 0.4
    tick_engine(1.0)
    return
  when :inject_virus
    stats['infections']['moko_virus_v1'] = 0.1
    stats['environment']['toxins'] += 20.0
  when :medicate
    # Antibiotics kill virus but also ruin gut microbiome
    stats['infections']['moko_virus_v1'] = 0.0
    stats['microbiome']['flora_diversity'] = 0.0
    stats['microbiome']['endotoxin_level'] = 1.0
  end
  tick_engine(1.0)
end

def render_ui
  clear_screen
  stats = @state[:stats]
  
  puts "#{C_BG_RED}#{C_BOLD}   DAIGAKU OS v2 — SOVEREIGN INTERACTIVE KERNEL   #{C_RESET}\n\n"
  
  puts "  👤 #{C_BOLD}#{stats['display_name']}#{C_RESET} (Gen #{stats['epigenetics']['generation_count']})"
  puts "  🧠 Mode: #{C_YELLOW}#{stats['behavior_mode']}#{C_RESET} | 🕒 Clock: #{format('%02d:00', stats['chrono']['internal_hour'] % 24)}"
  puts "-" * 60

  # Vitals
  hr = stats['physiology']['cardiac']['pulse_rate']
  temp = stats['homeostasis']['body_temp']
  ph = stats['homeostasis']['blood_ph']
  puts "  #{C_CYAN}【Vitals】#{C_RESET}"
  puts "  ♥️  HR: %3d BPM %s" % [hr, draw_bar(hr, 200, 10, hr > 120 ? C_RED : C_GREEN)]
  puts "  🌡️  °C: %4.1f   %s" % [temp, draw_bar(temp - 35, 8, 10, temp > 39.5 ? C_RED : C_YELLOW)]
  puts "  🩸  pH: %4.2f   %s" % [ph, draw_bar((ph - 6.8)*10, 10, 10, ph < 7.3 ? C_RED : C_CYAN)]
  puts ""

  # Energy
  glc = stats['metabolism']['glucose']
  atp = stats['metabolism']['atp_reserves'] * 100
  slp = stats['chrono']['sleep_pressure'] * 100
  puts "  #{C_YELLOW}【Energy & Rest】#{C_RESET}"
  puts "  🍬 Glc: %3d  %s" % [glc, draw_bar(glc, 150, 10, C_MAGENTA)]
  puts "  🔋 ATP: %3d%% %s" % [atp, draw_bar(atp, 100, 10, C_YELLOW)]
  puts "  🛏️ Slp: %3d%% %s" % [slp, draw_bar(slp, 100, 10, C_MAGENTA)]
  puts ""

  # Immunity & Gut
  lps = stats['microbiome']['endotoxin_level'] * 100
  srt = stats['microbiome']['serotonin_precursor'] * 100
  vrs = (stats['infections']['moko_virus_v1'] || 0) * 100
  puts "  #{C_GREEN}【Gut & Immunity】#{C_RESET}"
  puts "  🦠 Vrs: %3d%% %s" % [vrs, draw_bar(vrs, 100, 10, C_RED)]
  puts "  ☣️ LPS: %3d%% %s" % [lps, draw_bar(lps, 100, 10, C_RED)]
  puts "  🧠 Srt: %3d%% %s" % [srt, draw_bar(srt, 100, 10, C_GREEN)]
  puts "-" * 60

  puts "\n  #{C_BOLD}ACTIONS:#{C_RESET}"
  puts "  [1] 🍬 Eat Sugar       [2] 🥗 Eat Fiber"
  puts "  [3] 🛏️  Sleep (8h)     [4] 💻 Work (2h)"
  puts "  [5] 🏋️  Workout (1h)   [6] 🦠 Inject Virus"
  puts "  [7] 💊 Take Antibiotic [Q] 🚪 Quit"
  print "\n  > "
end

# 🎮 Game Loop
tick_engine(0.1) # Bootstrap
loop do
  render_ui
  input = STDIN.getch.downcase

  case input
  when '1' then apply_action(:eat_sugar)
  when '2' then apply_action(:eat_fiber)
  when '3' then apply_action(:sleep)
  when '4' then apply_action(:work)
  when '5' then apply_action(:workout)
  when '6' then apply_action(:inject_virus)
  when '7' then apply_action(:medicate)
  when 'q', "\u0003" then clear_screen; exit
  else
    tick_engine(1.0) # Idle for 1 hour
  end
end
