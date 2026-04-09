# frozen_string_literal: true

module Moko
  module Bio
    class FieldObserver
      # 🔍 Pro-Grade Naturalist Observer: Telemetry Analytics
      # Analyzes biological drift and metabolic efficiency.
      
      ObservationNotes = Struct.new(:timestamp, :env_status, :subject_vitality, :notes, keyword_init: true)

      def self.generate_report(state)
        # 📈 Telemetry: Analyze current vs initial/previous (derived from state)
        env = state[:environment]
        raid = state[:raid]
        bloodline = raid[:bloodline] || {}

        report = [
          "【高精度生物学的観測記録: #{Time.now.strftime('%H:%M:%S')}】",
          analyze_ecosystem(env, state[:toxin_load]),
          analyze_morphology(raid, bloodline),
          biometric_summary(state[:user]),
          "--- 観測継続。シミュレーション・エントロピーの収束を確認。 ---"
        ].join("\n")
        
        report.freeze
      end

      private

      def self.analyze_ecosystem(env, toxin_load)
        status = toxin_load > 0.7 ? "🌪️ [警戒] 毒素飽和" : "🌿 [安定] 好気性環境"
        ox_saturation = (env[:oxygen] / 1.0).round(1)
        
        "【環境解析】#{status} / 酸素飽和度: #{ox_saturation}%\n" \
        "└ 観測: 酸素による毒素中和プロセスは正常に機能中。"
      end

      def self.analyze_morphology(raid, bloodline)
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
