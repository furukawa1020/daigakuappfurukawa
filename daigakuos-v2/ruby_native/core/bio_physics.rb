# ruby_native/core/bio_physics.rb

class BioPhysics
  # ⚖️ Dynamic Bio-Physics System
  # Computes procedural deformation and pose data for rendering
  
  def self.calculate(monster_type, state, dt)
    case monster_type.to_s.downcase
    when /slime/
      SlimeDynamics.new(state).tick(dt)
    when /dragon/
      # Special handling for eastern vs western
      if monster_type.to_s.downcase.include?('eastern')
        EasternDragonDynamics.new(state).tick(dt)
      else
        DragonDynamics.new(state).tick(dt)
      end
    else
      { scale_x: 1.0, scale_y: 1.0, rotation: 0.0 }
    end
  end
end

class SlimeDynamics
  def initialize(state)
    @state = state || { x: 0.0, v: 0.0 }
    @k = 15.0 # Spring constant
    @c = 0.8  # Damping (higher = more honey-like)
  end

  def tick(dt)
    # 🧪 Mass-Spring-Damper Integration
    # Target is x=0 (equilibrium)
    force = -@k * @state[:x] - @c * @state[:v]
    accel = force # assume mass = 1
    
    new_v = @state[:v] + accel * dt
    new_x = @state[:x] + new_v * dt
    
    # Elasticity: stretch in one axis = squash in the other (Poisson effect)
    {
      x: new_x,
      v: new_v,
      scale_x: 1.0 + new_x * 0.5,
      scale_y: 1.0 - new_x * 0.5,
      wobble_factor: (new_x.abs * 10).to_i
    }
  end
end

class DragonDynamics
  def initialize(state)
    @state = state || { phase: 0.0 }
  end

  def tick(dt)
    # 🌬️ Aerodynamic Flap Cycle (Sine Wave)
    @state[:phase] += dt * 5.0 # Frequency
    
    # Wing angle (degrees)
    angle = Math.sin(@state[:phase]) * 45.0
    
    {
      phase: @state[:phase],
      wing_angle: angle,
      body_lift: Math.sin(@state[:phase] - 0.5) * 5.0 # Slight delay in body lift
    }
  end
end

class EasternDragonDynamics
  def initialize(state)
    @state = state || { segments: Array.new(5, 0.0), time: 0.0 }
  end

  def tick(dt)
    # 🏮 Sinuous Segmental Movement
    @state[:time] += dt * 3.0
    
    # Every segment follows the previous one with a phase shift
    new_segments = @state[:segments].each_with_index.map do |_, i|
      Math.sin(@state[:time] - (i * 0.8)) * 15.0
    end
    
    {
      time: @state[:time],
      segments: new_segments,
      curvature: new_segments.first.abs / 10.0
    }
  end
end
