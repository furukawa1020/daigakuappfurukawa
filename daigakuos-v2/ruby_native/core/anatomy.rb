# frozen_string_literal: true

module Moko
  module Bio
    # 🧬 Anatomy: Tissue-Level Integrity Engine
    # Specializes the health of physical barrier, connection, and power layers.
    
    class AnatomyEngine
      def self.initialize_anatomy(raid_state)
        raid_state[:anatomy] ||= {
          epithelial: { health: 1.0, barrier_leak: 0.0 },  # Skin/Lining
          connective: { health: 1.0, elasticity: 1.0 },   # Tendons/Ligaments
          muscular: { health: 1.0, peak_power: 1.0 }      # Contractile Tissue
        }
      end

      def self.tick(raid_state, dt_hours)
        ana = raid_state[:anatomy]
        phys = raid_state[:physiology]
        hormones = phys[:hormones]
        stress = phys[:organ_stress]
        
        # 🛡️ 1. Epithelial (Barrier)
        # Exposure to high environmental toxins damages the skin/lining
        toxin_ratio = (raid_state[:environment][:toxins] || 0.0) / 100.0
        if toxin_ratio > 0.6
          ana[:epithelial][:health] = [ana[:epithelial][:health] - (0.05 * dt_hours), 0.1].max
        end
        ana[:epithelial][:barrier_leak] = (1.0 - ana[:epithelial][:health]) * 0.5
        
        # ⛓️ 2. Connective Tissue (Tendons)
        # Adrenaline surge with high physical exertion causes tears
        if hormones[:adrenaline] > 0.8 && raid_state[:physics_velocity].to_f > 5.0
          ana[:connective][:health] = [ana[:connective][:health] - (0.02 * dt_hours), 0.2].max
        end
        ana[:connective][:elasticity] = (ana[:connective][:health] * 0.8 + 0.2).round(3)
        
        # 💪 3. Muscular Tissue (Power)
        # Acidosis (pH < 7.1) and prolonged stress damage muscle fibers
        ph = raid_state[:environment][:pH] || 7.4
        if ph < 7.1
          ana[:muscular][:health] = [ana[:muscular][:health] - (0.01 * dt_hours), 0.3].max
        end
        ana[:muscular][:peak_power] = (ana[:muscular][:health]).round(3)
        
        # 🩹 4. Repair (linked to Sleep)
        if raid_state[:is_sleeping]
          mult = 3.0
          ana[:epithelial][:health] = [ana[:epithelial][:health] + 0.05 * mult * dt_hours, 1.0].min
          ana[:connective][:health] = [ana[:connective][:health] + 0.01 * mult * dt_hours, 1.0].min
          ana[:muscular][:health]   = [ana[:muscular][:health]   + 0.03 * mult * dt_hours, 1.0].min
        end
        
        raid_state
      end
    end
  end
end
