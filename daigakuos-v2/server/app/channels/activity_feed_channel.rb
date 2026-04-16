class ActivityFeedChannel < ApplicationCable::Channel
  def subscribed
    stream_from "activity_feed"
  end

  def self.broadcast_moko_party(users)
    ActionCable.server.broadcast("activity_feed", {
      type: "moko_party",
      users: users.map(&:username),
      message: "#{users.map(&:username).join('と')}のモコたちが集まってパーティを始めました！🎉もこもこ！",
      occurred_at: Time.current
    })
  end
end
