# frozen_string_literal: true

module Moko
  module Bio
    # 🕵️ Field Observer: Naturalist's Telemetry Analytics
    # Converts deep physiological numbers into human-readable field notes.
    
    class FieldObserver
      def self.generate_report(state)
        raid = state[:raid]
        phys = raid[:physiology]
        metab = raid[:metabolism]
        env = state[:environment]
        bloodline = raid[:bloodline] || {}
        homeo = state[:homeostatic_modifiers] || { muscle_force: 1.0 }
        
        notes = []
        notes << "【個体解析レポート】対象: #{raid[:display_name]}"
        
        # 🧪 1. Hormonal & Metabolic Status
        adrenaline = phys[:hormones][:adrenaline]
        if adrenaline > 0.6
          notes << "● 警戒: アドレナリン急上昇を確認。代謝活動が過剰に亢進中。"
        end
        
        glucose = metab[:glucose]
        if glucose < 30.0
          notes << "● 消耗: 血糖値が臨界点近辺まで低下。捕食本能(Starving)への遷移を捕捉。"
        end
        
        # ❤️ 2. Organ-System Telemetry
        pulse = phys[:cardiac][:pulse_rate]
        ox = phys[:cardiac][:oxygen_saturation]
        notes << "● バイオメトリクス: 心拍 #{pulse}bpm / 血中酸素 #{ox}%"
        
        # 🧠 3. Neural Integrity
        cond = phys[:neural][:conduction_velocity]
        if cond < 0.7
          notes << "● 伝達異常: 神経伝達速度が #{(cond * 100).to_i}% まで減退。自律運動にノイズを検出。"
        end
        
        # ⚖️ 4. Homeostasis (pH & Temperature)
        ph = env[:pH] || 7.4
        temp = env[:body_temp] || 38.5
        notes << "● 恒常性維持: 体内pH #{ph} (理想 7.4) / 深部体温 #{temp}℃"
        
        if ph < 7.1
          notes << "● 警告: 代謝性アシドーシス。筋収縮力係数が #{homeo[:muscle_force].round(2)} まで抑制されている。"
        end
        
        # 💉 5. Immunological Defense (Phase 63)
        imm = raid[:immunology]
        protection = (imm[:protection_factor] * 100).to_i
        notes << "● 免疫系応答: 白血球活性 #{(imm[:leukocyte_activity] * 100).to_i}% / 抗体力価 #{imm[:antibody_titer].round(3)}"
        notes << "↳ 遮断効率: 環境毒素の #{protection}% を細胞レベルで無効化中。"
        
        # 🧬 6. Epigenetic Shift & Lineage Audit (Phase 63-66)
        epi = raid[:epigenetics]
        ger = raid[:germline]
        fibro = raid[:physiology][:fibrosis]
        methyl = epi[:methylation].values.sum
        
        notes << "● 家系監査: 第 #{epi[:generation_count]} 世代個体"
        
        if methyl > 0.1 || fibro.values.sum > 0.05
          notes << "● 変性解析: 恒久的な組織変質を検知。"
          notes << "↳ 累積エピジェネティック負荷: #{methyl.round(3)} / 組織線維化指数: #{fibro.values.sum.round(3)}"
          if epi[:methylation].values.any? { |v| v > 0.1 }
            notes << "↳ 特記: 祖先から引き継がれた「負の形質フラグメント」を検知。"
          end
        end
        
        # 🥚 7. Germline Integrity (Phase 66)
        notes << "● 生殖細胞監査: 継承整合性 #{(ger[:gamete_health] * 100).to_i}%"
        if ger[:gamete_health] < 0.7
          notes << "↳ 警告: 遺伝情報の劣化を検知。次世代に先天的な欠陥が受け継がれるリスクあり。"
        end
        
        # 📡 8. Sensory Perception Noise (Phase 64)
        sen = raid[:sensory]
        conduction = phys[:neural][:conduction_velocity]
        jitter = (1.0 - conduction) * 0.5
        if jitter > 0.1
          notes << "● 知覚異常: 入力信号のジッター値 #{jitter.round(2)}。外界認識にノイズが混入中。"
        end
        
        # ⛓️ 9. Anatomic & Structural Audit (Phase 65)
        skl = raid[:skeleton]
        ana = raid[:anatomy]
        notes << "● 構造完全性: 骨格強度 #{(skl[:integrity] * 100).to_i}% / 結合組織弾性 #{ana[:connective][:elasticity].round(2)}"
        
        notes.join("\n")
      end

      def self.biometric_summary(user)
        sync_rate = user[:metabolic_sync] || 50
        "【共生体同期】代相同調率: #{sync_rate}% / 生命維持効率: #{(user[:hp] / 1.0).round(1)}%"
      end
    end
  end
end
