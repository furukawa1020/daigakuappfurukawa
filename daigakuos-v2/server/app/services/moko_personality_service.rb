class MokoPersonalityService
  PERSONALITIES = {
    energetic: {
      tags: ["元気", "アクティブ"],
      templates: [
        "今日も最高の一日にしようぜ！🔥",
        "もっともっと集中して、世界を変えちゃおう！",
        "お前の集中力、マジでもこもこに輝いてるな！✨"
      ]
    },
    laid_back: {
      tags: ["のんびり", "マイペース"],
      templates: [
        "ゆっくり深呼吸して、自分のペースでいいんだよ。☕",
        "たまには休憩も大事。もこもこしていこう。",
        "お疲れ様。君の頑張りは僕が一番知ってるよ。💤"
      ]
    },
    intellectual: {
      tags: ["知性的", "冷静"],
      templates: [
        "効率的な集中パターンですね。分析通りです。📚",
        "知識は力なり。君の脳がもこもこ活性化しています。",
        "次のフェーズへの準備は整いました。進みましょう。"
      ]
    }
  }.freeze

  def self.generate_whisper(user)
    # 1. Global Event Priority
    world = MokoWorldService.current_status
    moko_defn = MokoDefinition::Registry.get('default')
    
    if moko_defn && moko_defn.on_global_event_block
      global_msg = user.instance_exec(world[:weather], &moko_defn.on_global_event_block)
      if global_msg
        return { message: global_msg, tags: ["ワールドイベント", world[:weather]] }
      end
    end

    # 2. Personality Fallback
    personality = select_personality(user)
    raw_msg = PERSONALITIES[personality][:templates].sample
    msg = MokoGrammarService.mokofize(raw_msg)
    { message: msg, tags: PERSONALITIES[personality][:tags] }
  end

  private

  def self.select_personality(user)
    # Simple logic: cycle through based on user id or random
    return :energetic if user.id % 3 == 0
    return :laid_back if user.id % 3 == 1
    :intellectual
  end
end
