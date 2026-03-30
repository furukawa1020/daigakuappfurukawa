class MokoWorldService
  WEATHER_TYPES = %w[sunny focus_storm moko_festival foggy starry_night]
  @@world_status = {
    weather: "sunny",
    event_name: "通常運行もこ",
    started_at: Time.current
  }.with_indifferent_access

  def self.current_status
    @@world_status
  end

  def self.change_weather!(weather_type = nil)
    weather_type ||= WEATHER_TYPES.sample
    @@world_status = {
      weather: weather_type,
      event_name: event_name_for(weather_type),
      started_at: Time.current
    }.with_indifferent_access
    
    # Broadcast to everyone!
    ActionCable.server.broadcast("activity_feed", {
      type: "world_weather_change",
      status: @@world_status
    })
    
    @@world_status
  end

  private

  def self.event_name_for(type)
    case type
    when "sunny" then "快晴もこ！集中日和だもこ！"
    when "focus_storm" then "集中ストーム発生中！XP1.5倍だもこ！🔥"
    when "moko_festival" then "もこ祭り開催中！プレゼントが届きやすいもこ！🎁"
    when "foggy" then "霧が深いもこ...焦らず進もうもこ。"
    when "starry_night" then "満天の星空だもこ。夜更かししすぎないでねもこ。💤"
    else "謎の現象が発生中だもこ！"
    end
  end
end
