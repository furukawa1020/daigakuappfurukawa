class WorldEventJob < ApplicationJob
  queue_as :default

  def perform
    new_weather = MokoWorldService.change_weather!
    Rails.logger.info "[MokoWorld] Global weather changed to #{new_weather[:weather]} - #{new_weather[:event_name]}"
    
    # Re-queue after 2-4 hours
    wait_time = rand(2..4).hours
    WorldEventJob.set(wait_until: wait_time.from_now).perform_later
  end
end
