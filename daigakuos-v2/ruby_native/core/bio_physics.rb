# frozen_string_literal: true

class BioPhysics
  # ⚖️ High-Precision Dynamic Bio-Physics System
  # Uses RK4 for stability and Verlet for sinewy constraints.
  
  def self.calculate(monster_type, state, dt)
    # Ensure dt is safe for high-precision calculation
    dt = dt.to_f.clamp(0.001, 0.1)
    
    case monster_type.to_s.downcase
    when /slime/
      SlimeDynamics.new(state).tick(dt)
    when /dragon/
      if monster_type.to_s.downcase.include?('eastern')
        EasternDragonDynamics.new(state).tick(dt)
      else
        DragonDynamics.new(state).tick(dt)
      end
    else
      { scale_x: 1.0, scale_y: 1.0, rotation: 0.0 }.freeze
    end
  end
end

class SlimeDynamics
  def initialize(state)
    @state = state || { x: 0.0, v: 0.0 }
    @k = 25.0 # Increased stiffness for RK4 stability
    @c = 2.0  # Damping (tuned for RK4)
  end

  # 🧪 Runge-Kutta 4th Order Integrator
  # Significantly more stable than Euler for harmonic oscillators
  def tick(dt)
    x = @state[:x].to_f
    v = @state[:v].to_f

    # k1
    k1_v = accel(x, v)
    k1_x = v

    # k2
    k2_v = accel(x + k1_x * dt / 2.0, v + k1_v * dt / 2.0)
    k2_x = v + k1_v * dt / 2.0

    # k3
    k3_v = accel(x + k2_x * dt / 2.0, v + k2_v * dt / 2.0)
    k3_x = v + k2_v * dt / 2.0

    # k4
    k4_v = accel(x + k3_x * dt, v + k3_v * dt)
    k4_x = v + k3_v * dt

    new_v = v + (dt / 6.0) * (k1_v + 2.0 * k2_v + 2.0 * k3_v + k4_v)
    new_x = x + (dt / 6.0) * (k1_x + 2.0 * k2_x + 2.0 * k3_x + k4_x)

    {
      x: new_x,
      v: new_v,
      scale_x: (1.0 + new_x * 0.4).round(4),
      scale_y: (1.0 - new_x * 0.4).round(4),
      wobble_factor: (new_x.abs * 10).to_i
    }.freeze
  end

  private

  def accel(x, v)
    -@k * x - @c * v
  end
end

class DragonDynamics
  def initialize(state)
    @state = state || { phase: 0.0 }
  end

  def tick(dt)
    # 🌬️ Aerodynamic Flap Cycle
    @state[:phase] += dt * 5.0 
    phase = @state[:phase]
    
    # Wing angle (degrees)
    angle = Math.sin(phase) * 45.0
    
    {
      phase: phase,
      wing_angle: angle.round(2),
      body_lift: (Math.sin(phase - 0.5) * 8.0).round(2)
    }.freeze
  end
end

class EasternDragonDynamics
  def initialize(state)
    # Verlet Integration uses current and previous positions
    @state = state || { 
      points: Array.new(6) { |i| { x: i * 20.0, y: 0.0, px: i * 20.0, py: 0.0 } },
      time: 0.0 
    }
  end

  def tick(dt)
    @state[:time] += dt * 2.0
    points = @state[:points]
    
    # 1. Verlet Step: Move segments
    # The head (index 0) is driven by a sinuous wave
    points[0][:px] = points[0][:x]
    points[0][:py] = points[0][:y]
    points[0][:y] = Math.sin(@state[:time]) * 30.0
    
    # Other points follow
    (1...points.size).each do |i|
      p = points[i]
      vx = (p[:x] - p[:px]) * 0.9 # Resistance
      vy = (p[:y] - p[:py]) * 0.9
      
      p[:px] = p[:x]
      p[:py] = p[:y]
      
      p[:x] += vx
      p[:y] += vy
    end
    
    # 2. Constraints Step: Maintain fixed length between segments
    5.times { satisfy_constraints(points) }
    
    {
      time: @state[:time],
      segments: points.map { |p| p[:y].round(2) },
      curvature: (points[1][:y] - points[0][:y]).abs.round(2)
    }.freeze
  end

  private

  def satisfy_constraints(points)
    link_length = 25.0
    (0...(points.size - 1)).each do |i|
      p1 = points[i]
      p2 = points[i+1]
      
      dx = p2[:x] - p1[:x]
      dy = p2[:y] - p1[:y]
      dist = Math.sqrt(dx*dx + dy*dy)
      diff = (link_length - dist) / dist
      
      p2[:x] += dx * diff * 0.5
      p2[:y] += dy * diff * 0.5
      p1[:x] -= dx * diff * 0.5
      p1[:y] -= dy * diff * 0.5
    end
  end
end
