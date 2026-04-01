class MokoNativeCommandService
  # Commands Native Bridge to execute Smartphone Hardware Functions
  
  def self.vibrate!(user, pattern: 'heavy')
    broadcast(user, 'vibrate', { pattern: pattern })
  end

  def self.notify!(user, title:, body:)
    broadcast(user, 'notify', { title: title, body: body })
  end

  def self.play_sound!(user, sound_name: 'quest_clear.mp3')
    broadcast(user, 'play_sound', { sound_name: sound_name })
  end

  private

  def self.broadcast(user, command, payload)
    # Broadcast to the global activity_feed, 
    # but the client-side listener will filter by target_username.
    ActionCable.server.broadcast("activity_feed", {
      type: "native_command",
      target_username: user.username,
      command: command,
      payload: payload,
      occurred_at: Time.current
    })
  end
end
