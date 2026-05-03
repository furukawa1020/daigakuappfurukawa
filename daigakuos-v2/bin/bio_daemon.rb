#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'time'
require 'fiddle/import'
require_relative '../ruby_native/core/rust_bridge'

# ==============================================================================
# 🕵️ Ruby Win32API Bindings (Fiddle)
# ==============================================================================
module User32
  extend Fiddle::Importer
  dlload 'user32'
  extern 'int GetForegroundWindow()'
  extern 'int GetWindowText(int, char*, int)'
  extern 'int MessageBoxA(int, char*, char*, int)'
end

def get_active_window_title
  hwnd = User32.GetForegroundWindow()
  return "Unknown" if hwnd == 0

  buff = "\0" * 512
  len = User32.GetWindowText(hwnd, buff, 512)
  # Handle encoding safely for Windows Shift-JIS/UTF-8
  title = buff[0, len]
  title.force_encoding("Windows-31J").encode("UTF-8") rescue title.force_encoding("UTF-8")
end

def send_windows_notification(title, message)
  # Uses PowerShell to trigger a native Windows 10/11 Toast Notification
  ps_script = <<~PS
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    $texts = $template.GetElementsByTagName("text")
    $texts[0].AppendChild($template.CreateTextNode("#{title}")) > $null
    $texts[1].AppendChild($template.CreateTextNode("#{message}")) > $null
    $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("DaigakuOS Bio-Kernel")
    $notifier.Show($toast)
  PS
  
  Thread.new { system("powershell", "-Command", ps_script) }
end

def show_message_box(title, message)
  # A blocking emergency popup
  User32.MessageBoxA(0, message, title, 0x00000030) # MB_ICONWARNING
end

# ==============================================================================
# 🧠 Activity Categorization
# ==============================================================================
def categorize_activity(title)
  lower = title.downcase
  if lower.include?("code") || lower.include?("texstudio") || lower.include?("cursor")
    "Work"
  elsif lower.include?("youtube") || lower.include?("netflix") || lower.include?("steam")
    "Entertainment"
  elsif lower.include?("twitter") || lower.include?("x.com") || lower.include?("discord")
    "SocialMedia"
  else
    "Unknown"
  end
end

# ==============================================================================
# 🐉 Bio-Daemon Main Loop
# ==============================================================================
puts "================================================="
puts "🛡️  DaigakuOS Bio-Daemon Started"
puts "   Monitoring real-world activity..."
puts "================================================="

unless Moko::Bio::RustBridge.active?
  puts "⚠️  [ERROR] Rust Kernel is not active. Please build it first."
  exit 1
end

# Load initial state (Placeholder, normally loaded from LocalStore)
@state = {
  encrypted_state: nil,
  stats: {
    "title" => "Moko Wyvern", "display_name" => "Moko Wyvern", "behavior_mode" => "Grazing",
    "is_sleeping" => false, "alert_level" => 0.0, "current_hp" => 1000000.0, "max_hp" => 1000000.0,
    "physiology" => {
      "neural" => { "conduction_velocity" => 1.0, "synaptic_stress" => 0.0, "reflex_latency" => 0.0 },
      "cardiac" => { "pulse_rate" => 60.0, "blood_pressure_delta" => 0.0, "oxygen_saturation" => 100.0 },
      "hormones" => { "adrenaline" => 0.05, "cortisol" => 0.1, "insulin" => 0.5, "metabolic_activator" => 1.0 },
      "organ_stress" => { "neural" => 0.0, "cardiac" => 0.0, "hepatic" => 0.0, "renal" => 0.0 },
      "fibrosis" => {}, "cellular_age" => 0.0, "mitochondrial_decay" => 0.0
    },
    "metabolism" => { "glucose" => 100.0, "atp_reserves" => 1.0, "lactate_level" => 0.0, "efficiency" => 1.0 },
    "immunology" => { "leukocyte_activity" => 0.1, "antibody_vault" => {}, "efficiency" => 1.0, "antigen_load" => 0.0, "protection_factor" => 0.0 },
    "microbiome" => { "flora_diversity" => 1.0, "symbiotic_ratio" => 0.8, "endotoxin_level" => 0.0, "fermentation_rate" => 1.0, "butyrate_level" => 0.5, "serotonin_precursor" => 0.7, "neuroactive_metabolites" => { "irritability" => 0.0, "calmness" => 0.1 } },
    "infections" => {}, "infectious_burden" => 0.0,
    "skeleton" => { "stress_level" => 0.0, "fractures" => [], "integrity" => 1.0, "calcium_reserves" => 1.0 },
    "anatomy" => { "epithelial" => {"health"=>1.0, "barrier_leak"=>0.0}, "connective" => {"health"=>1.0, "elasticity"=>1.0}, "muscular" => {"health"=>1.0, "peak_power"=>1.0} },
    "epigenetics" => { "methylation" => {}, "expression_bias" => 1.0, "generation_count" => 1 },
    "germline" => { "gamete_health" => 1.0, "mutagenic_pressure" => 0.0, "genetic_stability" => 1.0 },
    "chrono" => { "internal_hour" => 8.0, "melatonin_level" => 0.0, "cycle_type" => "diurnal", "alertness" => 1.0, "sleep_pressure" => 0.0 },
    "homeostasis" => { "body_temp" => 38.5, "blood_ph" => 7.4, "co2_partial" => 40.0, "bicarbonate" => 24.0 },
    "environment" => { "toxins" => 0.0, "oxygen" => 50.0, "ph" => 7.4, "weather" => "clear" },
    "ecology" => { "width" => 10, "height" => 10, "oxygen" => Array.new(100, 50.0), "toxins" => Array.new(100, 0.0), "rot" => Array.new(100, 0.0) },
    "last_activity" => "Unknown", "directive" => { "title" => "None", "message" => "", "level" => 0 }
  }
}

Moko::Bio::RustBridge.simulate_tick(@state, 0.1, 0.0) # Bootstrap
@last_notified_level = 0

loop do
  # 1. リアル世界のウィンドウを監視
  current_window = get_active_window_title
  category = categorize_activity(current_window)
  
  # Update state with real-world activity
  @state[:stats]['last_activity'] = category
  
  # Apply biological stress based on real-world activity
  case category
  when "Work"
    @state[:stats]['physiology']['hormones']['cortisol'] += 0.05
    @state[:stats]['metabolism']['atp_reserves'] -= 0.01
  when "Entertainment"
    @state[:stats]['metabolism']['atp_reserves'] -= 0.005
  when "SocialMedia"
    # Social media triggers dopamine spikes but also anxiety/irritability over time
    @state[:stats]['microbiome']['neuroactive_metabolites']['irritability'] += 0.05
    @state[:stats]['physiology']['hormones']['adrenaline'] += 0.05
  end

  # 2. Rust Kernel を実行 (1分間のシミュレーション = 0.016時間)
  Moko::Bio::RustBridge.simulate_tick(@state, 0.016, 0.0)
  
  stats = @state[:stats]
  directive = stats['directive'] || {}

  # ログ出力
  hr = stats['physiology']['cardiac']['pulse_rate']
  stress = stats['physiology']['neural']['synaptic_stress']
  puts "[#{Time.now.strftime('%H:%M:%S')}] Window: '#{current_window[0..30]}' (#{category}) | HR: #{hr.to_i} | Stress: #{format('%.2f', stress)}"

  # 3. リアル世界の介入 (Enforcement Directive)
  level = directive['level'].to_i
  
  if level > 0 && level > @last_notified_level
    puts "🚨 DIRECTIVE TRIGGERED: #{directive['title']} (Level #{level})"
    
    case level
    when 1..2
      # Level 1-2: 画面右下にWindowsのトースト通知を出す
      send_windows_notification(directive['title'], directive['message'])
    when 3
      # Level 3: 強制的なメッセージボックスで作業を妨害し、警告する
      show_message_box(directive['title'], directive['message'])
      # 本来ならここで Win32API LockWorkStation() を呼ぶことも可能
    end
  end

  # Alert level reset detection
  @last_notified_level = level if level > @last_notified_level
  @last_notified_level = 0 if level == 0

  # 10秒おきに監視
  sleep 10
end
