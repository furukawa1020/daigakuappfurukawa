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
        return false unless active?
        
        request = {
          state: raid_state,
          dt_hours: elapsed_hours.to_f,
          velocity: velocity.to_f
        }
        
        # Call the Rust kernel binary
        stdout, stderr, status = Open3.capture3(RUST_BINARY, stdin_data: request.to_json)
        
        if status.success?
          response = JSON.parse(stdout, symbolize_names: true) rescue nil
          if response && response[:state]
            # Atomically update the raid_state with the Rust-computed values
            raid_state.merge!(response[:state])
            return true
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
