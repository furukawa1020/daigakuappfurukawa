# Global Moko Definitions using our new DSL
if defined?(MokoDefinition)
  MokoDefinition.define 'default' do
  on_sync do
    # This block executes in the context of the User
    MokoGrammarService.mokofize("今日も同期を完了しますもこよ！")
  end

  on_global_event do |weather|
    case weather
    when "focus_storm" then "ストーム発生中もこ！一気に追い上げるチャンスもこ！🔥"
    when "moko_festival" then "お祭り気分だもこ！みんなで楽しももこ！🎁"
    else nil
    end
  end

  evolution_rule do
    # This block executes in context of User
    # Returns the target stage ID
    if level >= 100
      6 # Ultimate
    elsif sessions.count > 50 && level >= 20
      4 # Nobi-Moko (Growth variant)
    else
      nil # Fallback to standard logic
    end
  end
  end
end
