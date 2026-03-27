class MokoWhisperJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    whisper = MokoPersonalityService.generate_whisper(user)
    user.update!(whisper: whisper)
    
    # Broadcast to the user specifically (future use) or activity feed
    Rails.logger.info "[MokoWhisper] Generated new whisper for User ##{user.id}: #{whisper[:message]}"
  end
end
