# frozen_string_literal: true

module Moko
  module Bio
    # 🧠 Behavioral Ecology: Neuro-Endocrine Decision Engine
    # Behavior is an emergent property of hormonal state and metabolic reserves.
    
    class BehavioralEcologist
      BEHAVIOR_MODES = {
        grazing: { name: "安息", risk: 0.1, color: "green" },
        hunting: { name: "追跡", risk: 0.5, color: "orange" },
        starving: { name: "捕食本能", risk: 0.8, color: "red" },
        enraged: { name: "過剰防衛", risk: 1.2, color: "purple" },
        lethargic: { name: "代謝不全", risk: 0.05, color: "grey" }
      }

      def self.tick(raid_state, elapsed_hours, user_sessions, env_state = {})
        # This is now handled by the granular simulators in moko_engine
        # But we use the resulting hormones to update the mode
        update_behavior!(raid_state, env_state)
        generate_field_notes(raid_state)
        raid_state
      end

      def self.update_behavior!(raid_state, env_state)
        phys = raid_state[:physiology]
        hormones = phys[:hormones]
        metab = raid_state[:metabolism]
        stress = phys[:organ_stress]
        perception = raid_state[:perception] || { toxins: 0.0, oxygen: 50.0 }
        
        # 🧪 1. Hormonal & Perceptual Thresholds
        # Note: Brain uses perceived toxins, which may be noisy/laggy
        is_high_stress = hormones[:cortisol] > 0.7 || perception[:toxins] > 70.0
        is_adrenaline_surge = hormones[:adrenaline] > 0.6
        is_hypoglycemic = metab[:glucose] < 30.0
        is_exhausted = metab[:atp_reserves] < 0.2
        
        # 🧬 2. Behavioral State Machine (Phase 64: Added Sleep)
        if raid_state[:is_sleeping]
          raid_state[:behavior_mode] = :lethargic
        elsif is_exhausted || stress[:neural] > 0.8
          raid_state[:behavior_mode] = :lethargic
        elsif is_adrenaline_surge || is_high_stress
          raid_state[:behavior_mode] = :enraged
        elsif is_hypoglycemic
          raid_state[:behavior_mode] = :starving
        elsif raid_state[:alertness] > 0.6
          raid_state[:behavior_mode] = :hunting
        else
          raid_state[:behavior_mode] = :grazing
        end

        # 🎭 Naturalist Naming System
        raid_state[:display_name] = generate_scientific_title(raid_state)
      end

      def self.generate_scientific_title(raid_state)
        base = raid_state[:title] || "Moko Wyvern"
        phys = raid_state[:physiology]
        
        condition = if phys[:organ_stress][:neural] > 0.5 then "【神経衰弱】"
                    elsif phys[:hormones][:adrenaline] > 0.7 then "【亢進状態】"
                    elsif raid_state[:behavior_mode] == :lethargic then "【非活性】"
                    else ""
                    end
        
        "#{condition} #{base}"
      end

      def self.decide_action(raid_state, toxin_load)
        mode = raid_state[:behavior_mode] || :grazing
        mode_info = BEHAVIOR_MODES[mode]
        
        # Select base tactical pattern
        base_action = ActionPatterns.select_action(raid_state[:current_phase], toxin_load)
        
        # 🧬 Physiological Overrides
        case mode
        when :enraged
          base_action.merge(name: "激高: #{base_action[:name]}", damage_mult: 1.5)
        when :lethargic
          base_action.merge(name: "虚脱: #{base_action[:name]}", damage_mult: 0.4)
        when :starving
          base_action.merge(name: "捕食行動", damage_mult: 1.2)
        else
          base_action
        end
      end

      private

      def self.generate_field_notes(raid_state)
        # Delegated to FieldObserver, but could trigger specific notes here
      end
    end
  end
end
