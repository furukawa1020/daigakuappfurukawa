class ActivityFeedChannel < ApplicationCable::Channel
  def subscribed
    stream_from "activity_feed"
  end

  def self.broadcast_activity(user, type, metadata)
    ActionCable.server.broadcast("activity_feed", {
      username:      user.username,
      level:         user.level,
      activity_type: type,
      metadata:      metadata,
      occurred_at:   Time.current
    })
  end
end
