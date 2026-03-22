class Api::V1::SyncController < ApplicationController
  def push
    user = SyncService.new(device_id: params.require(:device_id), params: sync_params).perform_push
    # Exceptions (RecordInvalid, etc.) are elegantly caught by ApplicationController
    render json: { success: true, message: "Sync Push OK", last_sync_at: user.last_sync_at }, status: :ok
  end

  def pull
    # find_by! throws RecordNotFound if missing, which is handled globally
    user = User.find_by!(device_id: params.require(:device_id))
    
    # Use dedicated Serializer (PORO) to format the response
    render json: { success: true, payload: UserSerializer.new(user).to_hash }, status: :ok
  end

  private

  # Strong Parameters: structurally verified data
  def sync_params
    params.permit(
      :device_id, :level, :xp, :streak, :coins, :rest_days,
      sessions: [:started_at, :ended_at, :duration, :points, :quality],
      moko_items: [:item_id, :rarity, :unlocked_at],
      goal_nodes: [:title, :node_type, :estimate, :completed, :completed_at]
    )
  end
end
