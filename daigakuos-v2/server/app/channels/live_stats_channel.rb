class LiveStatsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "live_stats_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
