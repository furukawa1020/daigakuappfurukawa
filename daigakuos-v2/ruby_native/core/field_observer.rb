# frozen_string_literal: true

module Moko
  module Bio
    # 🕵️ Field Observer: Naturalist's Telemetry Analytics
    # Converts deep physiological numbers into human-readable field notes.
    
    class FieldObserver
      def self.generate_report(state)
        phys = state[:raid][:physiology]
        metab = state[:raid][:metabolism]
        env = state[:environment]
        bone = bloodline[:bone_density] || 1.0
        muscle = bloodline[:muscle_type] || :balanced
        
        insight = if bone > 1.2
                    "↳ 特記: 骨密度の顕著な増大を確認。物理的衝撃への適応が進んでいる。"
                  elsif muscle == :twitch
                    "↳ 特記: 速筋繊維の優位化を確認。瞬発的な挙動を優先する形質への移行。"
                  else
                    "↳ 特記: 標準的な身体形質を維持。安定的なエネルギー効率。"
                  end

        "【個体解析】対象: #{raid[:display_name]} / 骨密度係数: #{bone} / 筋組織: #{muscle}\n#{insight}"
      end

      def self.biometric_summary(user)
        sync_rate = user[:metabolic_sync] || 50
        "【共生体同期】代謝同調率: #{sync_rate}% / 生命維持効率: #{(user[:hp] / 1.0).round(1)}%"
      end
    end
  end
end
