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
        call_kernel(payload, raid_state)
      end

      def self.process_damage(raid_state, damage)
        payload = { command: 'process_damage', state: raid_state, damage: damage.to_f }
        call_kernel(payload, raid_state)
      end

      def self.rebirth(raid_state)
        payload = { command: 'rebirth', state: raid_state }
        call_kernel(payload, raid_state)
      end

      private

      def self.call_kernel(payload, target_state)
        return false unless active?
        
        # Call the Rust kernel binary
        stdout, stderr, status = Open3.capture3(RUST_BINARY, stdin_data: payload.to_json)
        
        if status.success?
          response = JSON.parse(stdout, symbolize_names: true) rescue nil
          if response && response[:state]
            # Atomically update the target_state with the Rust-computed values
            target_state.merge!(response[:state])
            return response[:result] || true
          end
        else
          STDERR.puts "🦀 [RUST KERNEL ERROR] #{stderr}"
        end
        
        false
      rescue => e
        STDERR.puts "🌉 [BRIDGE CRITICAL] #{e.message}"
        false
      end
    end
  end
end
