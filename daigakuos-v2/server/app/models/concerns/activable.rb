module Activable
  extend ActiveSupport::Concern

  included do
    has_many :activities, dependent: :destroy
  end

  def create_activity(type, metadata = {})
    activities.create!(
      activity_type: type,
      metadata: metadata
    )
    
    # Broadcast the activity live via ActionCable
    ActivityFeedChannel.broadcast_activity(self, type, metadata)
  end
end
