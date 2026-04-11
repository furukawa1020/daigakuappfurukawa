# frozen_string_literal: true

module Moko
  module Bio
    # 🧬 High-Precision Data-Driven Bio-Physics System
    # Mathematically linked to Physiology and Bloodline traits.
    
    # ⚖️ Immutable Data Objects for Performance
    PhysicsFrame = Struct.new(:scale_x, :scale_y, :rotation, :notes, keyword_init: true)

    class PhysicsEngine
      def self.calculate(monster_type, state, raid_state, dt)
        dt = dt.to_f.clamp(0.001, 0.1)
        bloodline = raid_state[:bloodline]
        phys = raid_state[:physiology] || PhysiologyEngine.initialize_physiology(raid_state)
        homeo = raid_state[:homeostatic_modifiers] || { muscle_force: 1.0, reaction_speed: 1.0 }
        
        # 🧠 Neural Factor: Nerve conduction velocity affects responsiveness
        # Low conduction causes jerky/laggy integration or jitter
        neural_latency = 1.0 - (phys[:neural][:conduction_velocity] || 1.0)
        jitter = (rand - 0.5) * neural_latency * 0.1
        
        # Adjust dt slightly based on reaction speed (Signal delay)
        effective_dt = dt * homeo[:reaction_speed]
        
        physics_output = case monster_type.to_s.downcase
        when /slime/
          SlimeDynamics.new(state, bloodline, homeo[:muscle_force]).tick(effective_dt)
        when /dragon/
          if monster_type.to_s.downcase.include?('eastern')
            EasternDragonDynamics.new(state, bloodline, homeo[:muscle_force]).tick(effective_dt)
          else
            DragonDynamics.new(state, bloodline, homeo[:muscle_force]).tick(effective_dt)
          end
        else
          { scale_x: 1.0, scale_y: 1.0, rotation: 0.0 }
        end
        
        # Apply Neural Jitter / signal noise
        physics_output.transform_values do |v|
          v.is_a?(Numeric) ? (v + jitter).round(4) : v
        end.freeze
      end
    end

    class SlimeDynamics
      def initialize(state, bloodline, force_mult = 1.0)
        @state = state || { x: 0.0, v: 0.0 }
        # 🧪 Bio-Link: Stiffness (k) and Damping (c) are derived from Bone Density and Muscle Type
        # ⚖️ Homeo-Link: pH Acidosis reduces muscle force mult (@k)
        @k = 20.0 * (bloodline[:bone_density] || 1.0) * force_mult
        @c = (bloodline[:muscle_type] == :tonic ? 3.0 : 1.5)
      end

      def tick(dt)
        x = @state[:x].to_f
        v = @state[:v].to_f

        # RK4 Integration: Stable Harmonics
        k1_v = accel(x, v)
        k2_v = accel(x + v * dt / 2.0, v + k1_v * dt / 2.0)
        k3_v = accel(x + (v + k1_v * dt / 2.0) * dt / 2.0, v + k2_v * dt / 2.0)
        k4_v = accel(x + (v + k2_v * dt / 2.0) * dt, v + k3_v * dt)

        new_v = v + (dt / 6.0) * (k1_v + 2.0 * k2_v + 2.0 * k3_v + k4_v)
        new_x = x + v * dt
        
        {
          x: new_x,
          v: new_v,
          scale_x: (1.0 + new_x * 0.4),
          scale_y: (1.0 - new_x * 0.4),
          wobble_factor: (new_x.abs * 10).to_i
        }
      end

      private
      
      def accel(x, v)
        -@k * x - @c * v
      end
    end

    class DragonDynamics
      def initialize(state, bloodline, force_mult = 1.0)
        @state = state || { phase: 0.0 }
        # 🌬️ Bio-Link: Flap frequency derived from Muscle Type & Lung Capacity
        # ⚖️ Homeo-Link: pH Acidosis reduces flap rate
        base_freq = (bloodline[:muscle_type] == :twitch ? 7.0 : 4.0)
        @freq = base_freq * (bloodline[:lung_capacity] || 1.0) * force_mult
      end

      def tick(dt)
        @state[:phase] += dt * @freq
        phase = @state[:phase]
        
        {
          phase: phase,
          wing_angle: (Math.sin(phase) * 45.0).round(2),
          body_lift: (Math.sin(phase - 0.5) * 8.0).round(2)
        }
      end
    end

    class EasternDragonDynamics
      def initialize(state, bloodline, force_mult = 1.0)
        @state = state || { 
          points: Array.new(6) { |i| { x: i * 20.0, y: 0.0, px: i * 20.0, py: 0.0 } },
          time: 0.0 
        }
        # 🏮 Bio-Link: Joint stiffness and length constraints
        @link_length = 25.0 * (bloodline[:bone_density] || 1.0)
        @tension = (bloodline[:muscle_type] == :tonic ? 0.95 : 0.8) * force_mult
      end

      def tick(dt)
        @state[:time] += dt * 2.0
        points = @state[:points]
        
        # Verlet Step
        points[0][:px] = points[0][:x]
        points[0][:py] = points[0][:y]
        points[0][:y] = Math.sin(@state[:time]) * 30.0
        
        (1...points.size).each do |i|
          p = points[i]
          vx = (p[:x] - p[:px]) * @tension
          vy = (p[:y] - p[:py]) * @tension
          p[:px], p[:py] = p[:x], p[:y]
          p[:x] += vx
          p[:y] += vy
        end
        
        5.times { satisfy_constraints(points) }
        
        {
          time: @state[:time],
          segments: points.map { |p| p[:y].round(2) },
          curvature: (points[1][:y] - points[0][:y]).abs.round(2)
        }
      end

      private
      
      def satisfy_constraints(points)
        (0...(points.size - 1)).each do |i|
          p1, p2 = points[i], points[i+1]
          dx, dy = p2[:x] - p1[:x], p2[:y] - p1[:y]
          dist = Math.sqrt(dx*dx + dy*dy)
          next if dist.zero?
          
          diff = (@link_length - dist) / dist
          p2[:x] += dx * diff * 0.5
          p2[:y] += dy * diff * 0.5
          p1[:x] -= dx * diff * 0.5
          p1[:y] -= dy * diff * 0.5
        end
      end
    end
  end
end
