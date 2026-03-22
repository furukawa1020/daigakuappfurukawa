class Api::V1::SyncController < ApplicationController
  def push
    user = User.find_or_initialize_by(device_id: params[:device_id])
    user.update!(
      level: params[:level] || user.level || 1,
      xp: params[:xp] || user.xp || 0,
      streak: params[:streak] || user.streak || 0,
      coins: params[:coins] || user.coins || 0,
      rest_days: params[:rest_days] || user.rest_days || 0,
      last_sync_at: Time.current
    )

    if params[:sessions].present?
      params[:sessions].each do |s|
        user.sessions.find_or_create_by!(started_at: s[:started_at]) do |session|
          session.ended_at = s[:ended_at]
          session.duration = s[:duration]
          session.points = s[:points]
          session.quality = s[:quality]
        end
      end
    end

    if params[:moko_items].present?
      params[:moko_items].each do |m|
        user.moko_items.find_or_create_by!(item_id: m[:item_id]) do |moko|
          moko.rarity = m[:rarity]
          moko.unlocked_at = m[:unlocked_at]
        end
      end
    end

    if params[:goal_nodes].present?
      params[:goal_nodes].each do |g|
        node = user.goal_nodes.find_or_initialize_by(title: g[:title])
        node.update!(
          node_type: g[:node_type],
          estimate: g[:estimate],
          completed: g[:completed],
          completed_at: g[:completed_at]
        )
      end
    end

    render json: { success: true, message: "Sync Push OK", last_sync_at: user.last_sync_at }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
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
      }
    else
      render json: { success: false, error: "User not found" }, status: :not_found
    end
  end
end
