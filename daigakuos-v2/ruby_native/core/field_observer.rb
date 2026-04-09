# frozen_string_literal: true

class FieldObserver
  # 🔍 Naturalist Observer: Objective Biological Logging
  # Replaces poetic prophecies with hard-science field notes.
  
  def self.generate_report(state)
    env = state[:environment]
    raid = state[:raid]
    bloodline = raid[:bloodline] || {}

    [
      header,
      observe_environment(env),
      observe_subject(raid, bloodline),
      metabolic_status(state[:user]),
      footer
    ].compact.join("\n")
  end

  private

  def self.header
    "【生物学的観測記録: #{Time.now.strftime('%Y-%m-%d %H:%M')}】"
  end

  def self.observe_environment(env)
    notes = "生息圏の酸素濃度は #{env[:oxygen].to_i}% 。"
    if env[:toxins] > 50
      notes += "外気中に高濃度の有毒副産物を確認。被験体の細胞組織への腐食ダメージが懸念される。"
    else
      notes += "大気は清浄に保たれており、好気性代謝が最適化されている。"
    end
    notes
  end

  def self.observe_subject(raid, bloodline)
    mode_name = MonsterBrain::BEHAVIOR_MODES[raid[:behavior_mode]][:name]
    notes = "観測対象: #{raid[:display_name]} (状態: #{mode_name})\n"
    notes += "形質的特徴: "
    notes += "骨密度 #{bloodline[:bone_density] || 1.0}x / 筋組織タイプ: #{bloodline[:muscle_type] || 'balanced'}\n"
    
    if raid[:hunger] > 70
      notes += "↳ 警告: 栄養飢餓状態を確認。捕食本能による攻撃的挙動への移行が予測される。"
    end
    notes
  end

  def self.metabolic_status(user)
    "共生体バイタル: HP #{user[:hp]}% / 代謝同調率: #{user[:order_level].to_i}段階"
  end

  def self.footer
    "--- 観測継続。生命維持装置の稼働に異常なし。 ---"
  end
end
