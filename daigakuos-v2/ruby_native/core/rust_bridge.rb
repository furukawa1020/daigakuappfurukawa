# frozen_string_literal: true
require 'json'
require 'open3'

module Moko
  module Bio
    # 🌉 Rust Bridge: High-Performance Kernel Interface
    # Delegates complex biological math to the compiled Rust core.
    
    class RustBridge
      RUST_BINARY = File.expand_path('../../rust_core/target/release/daigakuos-core', __FILE__)
      
      def self.active?
        @active ||= File.exist?(RUST_BINARY) || File.exist?("#{RUST_BINARY}.exe")
      end

      def self.simulate_tick(raid_state, elapsed_hours, velocity)
        payload = { command: 'simulate', state: raid_state, dt_hours: elapsed_hours.to_f, velocity: velocity.to_f }
        call_kernel(payload)
      end

      def self.process_damage(raid_state, damage)
        payload = { command: 'process_damage', state: raid_state, damage: damage.to_f }
        call_kernel(payload)
      end

      def self.rebirth(raid_state)
        payload = { command: 'rebirth', state: raid_state }
        call_kernel(payload)
      end

      private

      def self.call_kernel(payload)
        return false unless active?
        
        # 🕵️ Phase 77: Determine if we need to Bootstrap or use Encrypted State
        raid_state = payload[:state]
        is_bootstrap = raid_state[:encrypted_state].nil?
        
        if is_bootstrap
          payload[:command] = 'bootstrap'
        else
          # Swap raw state with the encrypted blob
          payload[:encrypted_state] = raid_state[:encrypted_state]
          payload.delete(:state)
        end
        
        # 🌉 Call the Rust kernel binary
        stdout, stderr, status = Open3.capture3(RUST_BINARY, stdin_data: payload.to_json)
        
        if status.success?
          response = JSON.parse(stdout, symbolize_names: true) rescue nil
          if response && response[:encrypted_state]
            # 🔐 Update the state with the NEW encrypted blob and RAW stats for UI
            raid_state[:encrypted_state] = response[:encrypted_state]
            raid_state.merge!(response[:state]) if response[:state]
            return response[:result] || true
          end
        else
          # 🚨 Security/Execution Failure
          STDERR.puts "🦀 [RUST KERNEL ERROR] #{stderr}"
          # If it's a security breach, the machine might already be locked
        end
        
        false
      rescue => e
        STDERR.puts "🌉 [BRIDGE CRITICAL] #{e.message}"
        false
      end
    end
  end
end
