# frozen_string_literal: true

module Moko
  module Bio
    # 🕵️ Field Observer: Naturalist's Telemetry Analytics
    # Converts deep physiological numbers into human-readable field notes.
    # PHASE 67: Nil-safe throughout — never crashes regardless of state completeness.

    class FieldObserver
      def self.generate_report(state)
        raid = state[:raid] || {}
        phys = raid[:physiology] || {}
        hormones = phys[:hormones] || {}
        cardiac  = phys[:cardiac]  || {}
        neural   = phys[:neural]   || {}
        organ_stress = phys[:organ_stress] || {}
        fibrosis = phys[:fibrosis] || {}
        metab    = raid[:metabolism] || {}
        env      = state[:environment] || {}
        homeo    = state[:homeostatic_modifiers] || raid[:homeostatic_modifiers] || {}

        notes = []
        name = raid[:display_name] || raid[:title] || '不明個体'
        notes << "【個体解析レポート】対象: #{name}"

        # 🧪 1. Hormonal & Metabolic Status
        adrenaline = hormones[:adrenaline] || 0.0
        notes << "● 警戒: アドレナリン急上昇を確認。代謝活動が過剰に亢進中。" if adrenaline > 0.6

        glucose = metab[:glucose] || 100.0
        notes << "● 消耗: 血糖値が臨界点近辺まで低下。捕食本能への遷移を捕捉。" if glucose < 30.0

        # ❤️ 2. Organ-System Telemetry
        pulse = cardiac[:pulse_rate] || 60
        ox    = cardiac[:oxygen_saturation] || 100.0
        notes << "● バイオメトリクス: 心拍 #{pulse}bpm / 血中酸素 #{ox}%"

        # 🧠 3. Neural Integrity
        cond = neural[:conduction_velocity] || 1.0
        notes << "● 伝達異常: 神経伝達速度が #{(cond * 100).to_i}% まで減退。自律運動にノイズを検出。" if cond < 0.7

        # ⚖️ 4. Homeostasis
        ph   = env[:pH] || 7.4
        temp = env[:body_temp] || 38.5
        notes << "● 恒常性維持: 体内pH #{ph} (理想 7.4) / 深部体温 #{temp}℃"
        muscle_force = (homeo[:muscle_force] || 1.0).round(2)
        notes << "● 警告: 代謝性アシドーシス。筋収縮力係数が #{muscle_force} まで抑制。" if ph < 7.1

        # 💉 5. Immunological Defense
        imm = raid[:immunology] || {}
        leuko   = (imm[:leukocyte_activity] || 0.0) * 100
        titer   = (imm[:antibody_titer]     || 0.0).round(3)
        protect = ((imm[:protection_factor] || 0.0) * 100).to_i
        notes << "● 免疫系応答: 白血球活性 #{leuko.to_i}% / 抗体力価 #{titer}"
        notes << "↳ 遮断効率: 環境毒素の #{protect}% を細胞レベルで無効化中。"

        # 🧬 6. Epigenetic & Lineage Audit
        epi    = raid[:epigenetics] || {}
        meth   = (epi[:methylation] || {}).values.sum
        gen    = epi[:generation_count] || 1
        fibro_sum = fibrosis.values.sum
        notes << "● 家系監査: 第 #{gen} 世代個体"
        if meth > 0.1 || fibro_sum > 0.05
          notes << "● 変性解析: 恒久的な組織変質を検知。"
          notes << "↳ エピジェネティック負荷: #{meth.round(3)} / 線維化指数: #{fibro_sum.round(3)}"
          
          # 🐚 Symbiotic Shell (Phase 69)
          div = (mic[:flora_diversity] || 1.0)
          if div > 0.8
            notes << "↳ 共生シナジー: 健全な細菌叢が遺伝的ドリフトを約 50% 緩和中。"
          end
          
          if (epi[:methylation] || {}).values.any? { |v| v > 0.1 }
            notes << "↳ 特記: 祖先由来の負の形질フラグメントを検知。"
          end
        end

        # 🥚 7. Germline Integrity
        ger = raid[:germline] || {}
        gh  = (ger[:gamete_health] || 1.0)
        notes << "● 生殖細胞監査: 継承整合性 #{(gh * 100).to_i}%"
        notes << "↳ 警告: 遺伝情報の劣化を検知。次世代に先天的欠陥リスクあり。" if gh < 0.7

        # 📡 8. Sensory Noise
        jitter = (1.0 - cond) * 0.5
        notes << "● 知覚異常: 入力信号のジッター値 #{jitter.round(2)}。外界認識にノイズ混入中。" if jitter > 0.1

        # 🦠 9. Microbial & Gut-Brain Audit (Phase 68)
        mic = raid[:microbiome] || {}
        metabolites = mic[:neuroactive_metabolites] || { irritability: 0.0, calmness: 0.1 }
        
        notes << "● 微生物叢監査: 多様性整合性 #{(mic[:flora_diversity].to_f * 100).to_i}% / 共生比率 #{(mic[:symbiotic_ratio].to_f * 100).to_i}%"
        if (mic[:endotoxin_level] || 0.0) > 0.4
          notes << "● 警告: 腸内細菌叢の乱れ（Dysbiosis）により、神経毒性を検知。暴走リスク増大中。"
        end
        notes << "↳ 向精神代謝産物: 鎮静係数 #{metabolites[:calmness].round(3)} / 易刺激性 #{metabolites[:irritability].round(3)}"
        
        # ⛓️ 10. Anatomic & Structural Audit (Phase 65)
        skl = raid[:skeleton] || {}
        ana = raid[:anatomy]  || {}
        con = (ana[:anatomy]&.dig(:connective, :elasticity) rescue nil) ||
              (ana.dig(:connective, :elasticity) rescue nil) || 1.0
        mpo = (ana.dig(:muscular, :peak_power) rescue nil) || 1.0
        integrity = ((skl[:integrity] || 1.0) * 100).to_i
        notes << "● 構造完全性: 骨格強度 #{integrity}% / 結合組織弾性 #{con.round(2)}"
        notes << "● 警告: 骨格系に構造的破綻（骨折）を確認。力学的バイアスによる運動障害が発生中。" if (skl[:fractures] || []).any?
        notes << "↳ 骨格負荷: #{(skl[:stress_level] || 0) > 1.0 ? '臨界' : '許容範囲'} / 筋組織出力係数: #{mpo.round(2)}"

        # ⏳ 10. Chronobiology & Aging
        chr      = raid[:chrono] || {}
        age      = phys[:cellular_age]        || 0.0
        decay    = ((phys[:mitochondrial_decay]|| 0.0) * 100).to_i
        hour     = (chr[:internal_hour] || 12.0).to_i
        sleeping = raid[:is_sleeping] ? "【深睡眠 / 組織修復中】" : "活性化状態"
        notes << "● バイオリズム: 体内時刻 #{hour}:00 / #{sleeping}"
        notes << "● 生体時間: 累積細胞寿命 #{age.round(1)}h / ミトコンドリア劣化率 #{decay}%"

        notes.join("\n")
      rescue => e
        "【観測エラー】#{e.class}: #{e.message}"
      end

      def self.biometric_summary(user)
        sync_rate = (user || {})[:metabolic_sync] || 50
        "【共生体同期】代謝同調率: #{sync_rate}% / 生命維持: #{((user || {})[:hp] || 0).round(1)}"
      end
    end
  end
end
