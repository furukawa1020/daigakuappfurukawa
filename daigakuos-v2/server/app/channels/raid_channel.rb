class RaidChannel < ApplicationCable::Channel
  def subscribed
    stream_from "raid_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
