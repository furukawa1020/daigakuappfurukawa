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
        
        # 🧬 6. Epigenetic Shift & Fibrosis (Phase 63/64)
        epi = raid[:epigenetics]
        fibro = raid[:physiology][:fibrosis]
        methyl = epi[:methylation].values.sum
        if methyl > 0.1 || fibro.values.sum > 0.05
          notes << "● 変性解析: 恒久的な組織変質を検知。"
          notes << "↳ DNA メチル化率: #{methyl.round(3)} / 組織線維化指数: #{fibro.values.sum.round(3)}"
          if fibro[:neural] > 0.1
            notes << "↳ 警戒: 神経線維化により、最大伝達速度が制限されている。"
          end
        end
        
        # 📡 7. Sensory Perception Noise (Phase 64)
        sen = raid[:sensory]
        conduction = phys[:neural][:conduction_velocity]
        jitter = (1.0 - conduction) * 0.5
        if jitter > 0.1
          notes << "● 知覚異常: 入力信号のジッター値 #{jitter.round(2)}。外界認識にノイズが混入中。"
        end
        
        # ⏳ 8. Chronobiology & Aging (Phase 64)
        chr = raid[:chrono]
        age = phys[:cellular_age] || 0.0
        decay = (phys[:mitochondrial_decay] * 100).to_i
        night_status = raid[:is_sleeping] ? "【深睡眠 / 組織修復中】" : "活性化状態"
        
        notes << "● バイオリズム: 体内時刻 #{chr[:internal_hour].to_i}:00 / #{night_status}"
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
