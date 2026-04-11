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
        
        # 🧬 6. Epigenetic Shift Detection (Phase 63)
        epi = raid[:epigenetics]
        methyl = epi[:methylation].values.sum
        if methyl > 0.1
          notes << "● 遺伝子発現解析: DNAメチル化の進行を検地。環境ストレスによるエピジェネティックな形質固定が発生。"
          notes << "↳ 特記: 代謝率調節遺伝子の発現が #{(epi[:methylation][:metabolic_rate] * 100).to_i}% 抑制されている。"
        end
        
        # ⏳ 7. Cellular Aging
        age = raid[:physiology][:cellular_age] || 0.0
        decay = (raid[:physiology][:mitochondrial_decay] * 100).to_i
        notes << "● 生体時間: 累積細胞寿命 #{age.round(1)}h / ミトコンドリア劣化率 #{decay}%"
        
        notes.join("\n")
      end

      def self.biometric_summary(user)
        sync_rate = user[:metabolic_sync] || 50
        "【共生体同期】代相同調率: #{sync_rate}% / 生命維持効率: #{(user[:hp] / 1.0).round(1)}%"
      end
    end
  end
end
