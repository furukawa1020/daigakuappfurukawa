class Api::V1::WorldController < ApplicationController
  def status
    status = MokoWorldService.current_status
    
    render json: {
      weather: status[:weather],
      event_name: status[:event_name],
      started_at: status[:started_at],
      raid_buff: status[:raid_buff],
      raid_buff_ends_at: status[:raid_buff_ends_at],
      active_raid: status[:active_raid].present?
    }
  end
end
