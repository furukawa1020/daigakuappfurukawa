class SyncService
  def initialize(device_id:, params:)
    @device_id = device_id
    @params = params
  end

  def perform_push
    # Execute all database operations within a transaction.
    # If any operation fails and raises an exception (like RecordInvalid), 
    # it rolls back everything, ensuring the database is never left in an inconsistent state.
    ActiveRecord::Base.transaction do
      user = User.find_or_initialize_by(device_id: @device_id)
      
      # Update user stats safely
      user.update!(
        level: @params[:level] || user.level || 1,
        xp: @params[:xp] || user.xp || 0,
        streak: @params[:streak] || user.streak || 0,
        coins: @params[:coins] || user.coins || 0,
        rest_days: @params[:rest_days] || user.rest_days || 0,
        last_sync_at: Time.current
      )

      sync_sessions(user, @params[:sessions]) if @params[:sessions].present?
      sync_moko_items(user, @params[:moko_items]) if @params[:moko_items].present?
      sync_goal_nodes(user, @params[:goal_nodes]) if @params[:goal_nodes].present?
      
      user
    end

    # Side-load heavy data processing via ActiveJob so the API responds instantly
    ProcessUserStatsJob.perform_later(user.id) if user.persisted?
    
    user
  end

  private

  def sync_sessions(user, sessions_params)
    sessions_params.each do |s|
      user.sessions.find_or_create_by!(started_at: s[:started_at]) do |session|
        session.ended_at = s[:ended_at]
        session.duration = s[:duration]
        session.points   = s[:points]
        session.quality  = s[:quality]
      end
    end
  end

  def sync_moko_items(user, moko_params)
    moko_params.each do |m|
      user.moko_items.find_or_create_by!(item_id: m[:item_id]) do |moko|
        moko.rarity      = m[:rarity]
        moko.unlocked_at = m[:unlocked_at]
      end
    end
  end

  def sync_goal_nodes(user, goal_params)
    goal_params.each do |g|
      node = user.goal_nodes.find_or_initialize_by(title: g[:title])
      node.update!(
        node_type:    g[:node_type],
        estimate:     g[:estimate],
        completed:    g[:completed],
        completed_at: g[:completed_at]
      )
    end
  end
end
