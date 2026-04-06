class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_global"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def speak(data)
    # data: { "username" => "...", "content" => "..." }
    ActionCable.server.broadcast("chat_global", {
      username: data["username"],
      content: data["content"],
      timestamp: Time.current.strftime("%H:%M")
    })
  end
end
