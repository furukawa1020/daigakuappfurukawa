#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'io/console'
require 'time'
require_relative '../ruby_native/core/rust_bridge'

# 🎨 ANSI Escape Sequences for Absolute Positioning & UI
C_RESET   = "\e[0m"
C_BOLD    = "\e[1m"
C_DIM     = "\e[2m"
C_RED     = "\e[38;5;196m"
C_GREEN   = "\e[38;5;46m"
C_YELLOW  = "\e[38;5;226m"
C_BLUE    = "\e[38;5;33m"
C_MAGENTA = "\e[38;5;201m"
C_CYAN    = "\e[38;5;51m"
C_WHITE   = "\e[38;5;231m"
C_BG_DARK = "\e[48;5;234m"

def move_cursor(row, col)
  "\e[#{row};#{col}H"
end

def clear_screen
  "\e[H\e[2J\e[3J"
end

def hide_cursor
  "\e[?25l"
end

def show_cursor
  "\e[?25h"
end

def draw_bar(val, max, width = 15, color = C_GREEN)
  fill = ((val.to_f / max) * width).round.clamp(0, width)
  empty = width - fill
  "#{color}#{'█' * fill}#{C_DIM}#{'░' * empty}#{C_RESET}"
end

# ─────────────────────────────────────────────────────────────────────────────
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

@event_log = ["System Initialized.", "Bio-Kernel Rust Bridge Connected."]
def log(msg, color = C_WHITE)
  @event_log.push("#{color}#{Time.now.strftime('%H:%M:%S')} | #{msg}#{C_RESET}")
  @event_log.shift if @event_log.size > 8
end

# ─────────────────────────────────────────────────────────────────────────────
# 🐉 Art Rendering
def get_wyvern_art(stats)
  mode = stats['behavior_mode']
  is_sleeping = stats['is_sleeping']
  temp = stats['homeostasis']['body_temp']

  if is_sleeping
    return [
      "      z Z z     ",
      "    _   Z       ",
      "  -(_)-.        ",
      "  /____|        ",
      "  ( _ _ )       "
    ], C_BLUE
  elsif temp > 40.0 || mode == 'Enraged'
    return [
      "    (💢)      ",
      "   \\_🔥_/    ",
      "   ( o o )      ",
      "   / > < \\     ",
      "  (_______)     "
    ], C_RED
  elsif mode == 'Lethargic'
    return [
      "      ...       ",
      "    _   _       ",
      "  -(_)-(_)      ",
      "  /      \\     ",
      "  ( - _ - )     "
    ], C_DIM
  else
    return [
      "      ♪         ",
      "    _   _       ",
      "  -(_)-(_)      ",
      "  /      \\     ",
      "  ( ^ _ ^ )     "
    ], C_GREEN
  end
end

# ─────────────────────────────────────────────────────────────────────────────
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
    stats['microbiome']['flora_diversity'] -= 0.05
    log("Ate Sugar: Glucose spiked. Flora diversity decreased.", C_MAGENTA)
  when :eat_fiber
    stats['metabolism']['glucose'] += 10.0
    stats['microbiome']['flora_diversity'] += 0.1
    log("Ate Fiber: Gut flora diversity increased.", C_GREEN)
  when :sleep
    log("Going to sleep for 8 hours...", C_BLUE)
    stats['is_sleeping'] = true
    tick_engine(8.0)
    stats['is_sleeping'] = false
    log("Woke up. Adenosine cleared.", C_CYAN)
    return
  when :work
    stats['physiology']['hormones']['cortisol'] += 0.3
    stats['last_activity'] = "work"
    log("Worked hard. Cortisol spiked.", C_YELLOW)
    tick_engine(2.0)
    return
  when :workout
    stats['metabolism']['lactate_level'] += 0.5
    stats['physiology']['hormones']['adrenaline'] += 0.4
    log("Workout complete. Lactate acidosis triggered.", C_RED)
    tick_engine(1.0)
    return
  when :inject_virus
    stats['infections']['moko_virus_v1'] = 0.1
    stats['environment']['toxins'] += 20.0
    log("WARNING: Bio-hazard injected.", "\e[41;37;1m")
  when :medicate
    stats['infections']['moko_virus_v1'] = 0.0
    stats['microbiome']['flora_diversity'] = 0.0
    stats['microbiome']['endotoxin_level'] = 1.0
    log("Antibiotics taken. Virus cleared, but microbiome destroyed.", C_YELLOW)
  end
  tick_engine(1.0)
end

# ─────────────────────────────────────────────────────────────────────────────
# 📺 UI Render Loop
def render_ui
  stats = @state[:stats]
  out = String.new
  out << move_cursor(1, 1) << C_BG_DARK
  
  # Header
  out << " #{C_BOLD}DAIGAKU OS v2 — NATIVE RUST BIO-KERNEL TERMINAL INTERFACE#{C_RESET} \n"
  out << " ≡" * 38 << "\n"
  
  # Layout: Left column (Stats), Right column (Art & Logs)
  
  hr   = stats['physiology']['cardiac']['pulse_rate']
  temp = stats['homeostasis']['body_temp']
  ph   = stats['homeostasis']['blood_ph']
  glc  = stats['metabolism']['glucose']
  atp  = stats['metabolism']['atp_reserves'] * 100
  slp  = stats['chrono']['sleep_pressure'] * 100
  mel  = stats['chrono']['melatonin_level'] * 100
  lps  = stats['microbiome']['endotoxin_level'] * 100
  srt  = stats['microbiome']['serotonin_precursor'] * 100
  vrs  = (stats['infections']['moko_virus_v1'] || 0) * 100
  ab   = (stats['immunology']['antibody_vault']['moko_virus_v1'] || 0) * 100

  # Panel 1: Identity & Clock
  out << move_cursor(4, 2) << "#{C_CYAN}❖ IDENTITY ──────────────────#{C_RESET}"
  out << move_cursor(5, 4) << "Name : #{C_BOLD}#{stats['display_name']}#{C_RESET}"
  out << move_cursor(6, 4) << "Mode : #{C_YELLOW}#{stats['behavior_mode']}#{C_RESET}"
  out << move_cursor(7, 4) << "Clock: #{format('%02d:00', stats['chrono']['internal_hour'] % 24)} (Gen #{stats['epigenetics']['generation_count']})"

  # Panel 2: Homeostasis
  out << move_cursor(9, 2) << "#{C_CYAN}❖ HOMEOSTASIS ───────────────#{C_RESET}"
  out << move_cursor(10, 4) << "HR   : %3d BPM %s" % [hr, draw_bar(hr, 200, 10, hr > 120 ? C_RED : C_GREEN)]
  out << move_cursor(11, 4) << "Temp : %4.1f°C %s" % [temp, draw_bar(temp - 35, 8, 10, temp > 39.5 ? C_RED : C_YELLOW)]
  out << move_cursor(12, 4) << "pH   : %4.2f   %s" % [ph, draw_bar((ph - 6.8)*10, 10, 10, ph < 7.3 ? C_RED : C_CYAN)]

  # Panel 3: Metabolism
  out << move_cursor(14, 2) << "#{C_CYAN}❖ METABOLISM & CIRCADIAN ────#{C_RESET}"
  out << move_cursor(15, 4) << "ATP  : %3d%%   %s" % [atp, draw_bar(atp, 100, 10, C_YELLOW)]
  out << move_cursor(16, 4) << "Gluc : %3d    %s" % [glc, draw_bar(glc, 150, 10, C_MAGENTA)]
  out << move_cursor(17, 4) << "Sleep: %3d%%   %s" % [slp, draw_bar(slp, 100, 10, C_MAGENTA)]
  out << move_cursor(18, 4) << "Mela : %3d%%   %s" % [mel, draw_bar(mel, 100, 10, C_BLUE)]

  # Panel 4: Microbiome
  out << move_cursor(20, 2) << "#{C_CYAN}❖ GUT MICROBIOME & IMMUNE ───#{C_RESET}"
  out << move_cursor(21, 4) << "Virus: %3d%%   %s" % [vrs, draw_bar(vrs, 100, 10, C_RED)]
  out << move_cursor(22, 4) << "AntiB: %3d%%   %s" % [ab, draw_bar(ab, 100, 10, C_CYAN)]
  out << move_cursor(23, 4) << "LPS  : %3d%%   %s" % [lps, draw_bar(lps, 100, 10, C_RED)]
  out << move_cursor(24, 4) << "Serot: %3d%%   %s" % [srt, draw_bar(srt, 100, 10, C_GREEN)]

  # Right Column: Art
  art, art_color = get_wyvern_art(stats)
  out << move_cursor(4, 45) << "#{C_CYAN}❖ VISUAL ─────────────────────#{C_RESET}"
  art.each_with_index do |line, i|
    out << move_cursor(6 + i, 48) << "#{art_color}#{line}#{C_RESET}"
  end

  # Right Column: Logs
  out << move_cursor(13, 45) << "#{C_CYAN}❖ SYSTEM LOG ─────────────────#{C_RESET}"
  @event_log.each_with_index do |log_msg, i|
    out << move_cursor(15 + i, 47) << log_msg
  end

  # Bottom: Controls
  out << move_cursor(26, 2) << " ≡" * 38
  out << move_cursor(28, 4) << "#{C_BOLD}[1]#{C_RESET} Sugar  #{C_BOLD}[2]#{C_RESET} Fiber  #{C_BOLD}[3]#{C_RESET} Sleep  #{C_BOLD}[4]#{C_RESET} Work  #{C_BOLD}[5]#{C_RESET} Workout  #{C_BOLD}[6]#{C_RESET} Virus  #{C_BOLD}[7]#{C_RESET} Meds  #{C_BOLD}[Q]#{C_RESET} Quit"
  
  out << move_cursor(30, 0)
  print out
end

# ─────────────────────────────────────────────────────────────────────────────
# 🎮 Main Event Loop
tick_engine(0.1) # Bootstrap
print clear_screen
print hide_cursor

last_tick = Time.now

begin
  loop do
    # Non-blocking input handling
    begin
      input = STDIN.read_nonblock(1).downcase
      case input
      when '1' then apply_action(:eat_sugar)
      when '2' then apply_action(:eat_fiber)
      when '3' then apply_action(:sleep)
      when '4' then apply_action(:work)
      when '5' then apply_action(:workout)
      when '6' then apply_action(:inject_virus)
      when '7' then apply_action(:medicate)
      when 'q', "\u0003" then break
      end
    rescue IO::WaitReadable
      # No input available right now
    end

    # Auto-tick biological engine (1 hour passes every 1 second of real time)
    if Time.now - last_tick > 1.0
      tick_engine(1.0)
      last_tick = Time.now
    end

    render_ui
    sleep 0.05 # ~20 FPS render loop
  end
ensure
  print show_cursor
  print clear_screen
end
