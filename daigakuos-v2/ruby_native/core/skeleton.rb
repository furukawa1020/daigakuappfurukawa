# frozen_string_literal: true

module Moko
  module Bio
    # 🦴 Skeleton: Structural Integrity Engine
    # Models bone stress and mechanical failure.
    
    class SkeletonEngine
      def self.initialize_skeleton(raid_state)
        raid_state[:skeleton] ||= {
          stress_level: 0.0,
          fractures: [], # List of fractured zones (e.g. :left_wing, :leg)
          integrity: 1.0, # 0.0 to 1.0
          calcium_reserves: 1.0
        }
      end

      def self.tick(raid_state, physics_velocity, dt_hours)
        skl = raid_state[:skeleton]
        pheno = raid_state[:phenotype] || raid_state[:bloodline]
        
        # 🔩 1. Calculate Mechanical Load
        # Load increases dramatically with velocity (KE = 0.5mv^2)
        vel_mag = physics_velocity.is_a?(Numeric) ? physics_velocity.abs : 1.0
        instant_load = (vel_mag**1.5) * 0.1
        
        # 🦴 2. Stress Accumulation
        # Density (BoneDensity) acts as the resistance factor
        density = pheno[:bone_density] || 1.0
        stress_increment = (instant_load / density) * dt_hours
        skl[:stress_level] = [skl[:stress_level] + stress_increment, 2.0].min
        
        # 🧱 3. Fracture Logic
        # If stress crosses the density limit, a fracture occurs
        if skl[:stress_level] > (density * 1.5) && rand < (skl[:stress_level] * 0.1)
          skl[:fractures] << :structural_fracture unless skl[:fractures].include?(:structural_fracture)
          skl[:integrity] = [skl[:integrity] - 0.2, 0.1].max
        end
        
        # 🩹 4. Natural Repair (Remodeling)
        # Slow repair during rest (no movement)
        if vel_mag < 0.1
          repair_speed = 0.05 * (raid_state[:is_sleeping] ? 5.0 : 1.0)
          skl[:stress_level] = [skl[:stress_level] - repair_speed * dt_hours, 0.0].max
          
          # Integrity recovery (much slower)
          if skl[:stress_level] < 0.1
            skl[:integrity] = [skl[:integrity] + 0.01 * dt_hours, 1.0].min
            skl[:fractures].clear if skl[:integrity] > 0.95
          end
        end
        
        raid_state
      end
    end
  end
end
