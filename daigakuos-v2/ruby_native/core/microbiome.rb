# frozen_string_literal: true

module Moko
  module Bio
    # 🦠 Microbiome: Internal Ecosystem Engine
    # Models the symbiotic relationship between external toxins and internal bacterial flora.
    
    class MicrobiomeEngine
      def self.initialize_microbiome(raid_state)
        raid_state[:microbiome] ||= {
          flora_diversity: 1.0, # 0.0 to 1.0
          symbiotic_ratio: 0.8, # Ratio of helpful bacteria
          endotoxin_level: 0.0, # Byproducts of opportunistic bacteria
          fermentation_rate: 1.0, # Efficiency of toxin processing assistance
          neuroactive_metabolites: { irritability: 0.0, calmness: 0.1 }
        }
      end

      def self.tick(raid_state, dt_hours)
        mic = raid_state[:microbiome]
        env = raid_state[:environment]
        phys = raid_state[:physiology]
        
        # 🧪 1. pH & Toxin Impact on Diversity
        # Extreme pH (Acidosis/Alkalosis) wipes out sensitive symbionts
        ph = env[:pH] || 7.4
        ph_stress = (ph - 7.4).abs
        if ph_stress > 0.4
          mic[:flora_diversity] = [mic[:flora_diversity] - (0.05 * ph_stress * dt_hours), 0.1].max
        end
        
        # 🤢 2. Opportunistic Bloom (Opportunistic bacteria love toxins)
        toxin_infiltration = (env[:toxins] || 0.0) / 100.0
        if toxin_infiltration > 0.5
          # High toxins reduce symbiotic ratio and increase endotoxins
          mic[:symbiotic_ratio] = [mic[:symbiotic_ratio] - (0.02 * dt_hours), 0.1].max
          mic[:endotoxin_level] = [mic[:endotoxin_level] + (0.03 * toxin_infiltration * dt_hours), 1.0].min
        else
          # Natural recovery of symbionts
          mic[:symbiotic_ratio] = [mic[:symbiotic_ratio] + (0.01 * dt_hours), 0.9].min
          mic[:endotoxin_level] = [mic[:endotoxin_level] - (0.05 * dt_hours), 0.0].max
        end
        
        # 🧠 3. Neuro-active Metabolite Production (Gut-Brain Axis)
        # Endotoxins stimulate 'Irritability' (Enraged bias)
        mic[:neuroactive_metabolites][:irritability] = (mic[:endotoxin_level] * 0.8).round(4)
        # Healthy diversity produces 'Calmness' (Grazing bias)
        mic[:neuroactive_metabolites][:calmness] = (mic[:flora_diversity] * mic[:symbiotic_ratio] * 0.2).round(4)
        
        # ⚙️ 4. Metabolic Assistance
        # Helpful bacteria help process toxins. If diversity is low, toxin processing slows down.
        mic[:fermentation_rate] = (mic[:flora_diversity] * mic[:symbiotic_ratio] * 0.5 + 0.5).round(3)
        
        raid_state
      end
    end
  end
end
