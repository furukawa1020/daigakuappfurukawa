class Api::V1::SyncController < ApplicationController
  def push
    user = SyncService.new(device_id: params[:device_id], params: sync_params).perform_push
    render json: { success: true, message: "Sync Push OK", last_sync_at: user.last_sync_at }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    # Renders the exact validation error (e.g. "Level must be greater than 0")
    render json: { success: false, error: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :internal_server_error
  end

  def pull
    user = User.find_by(device_id: params[:device_id])
    if user
      render json: {
        success: true,
        user: user.as_json(except: [:id, :created_at, :updated_at]),
        sessions: user.sessions.as_json(except: [:id, :user_id, :created_at, :updated_at]),
        moko_items: user.moko_items.as_json(except: [:id, :user_id, :created_at, :updated_at]),
        goal_nodes: user.goal_nodes.as_json(except: [:id, :user_id, :created_at, :updated_at])
      }, status: :ok
    else
      render json: { success: false, error: "User not found" }, status: :not_found
    end
  end

  private

  # Strong Parameters: only allows explicitly permitted structured data to pass through.
  # This prevents malicious injection into our models.
  def sync_params
    params.permit(
      :device_id, :level, :xp, :streak, :coins, :rest_days,
      sessions: [:started_at, :ended_at, :duration, :points, :quality],
      moko_items: [:item_id, :rarity, :unlocked_at],
      goal_nodes: [:title, :node_type, :estimate, :completed, :completed_at]
    )
  end
end
