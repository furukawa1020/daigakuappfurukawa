class UserSerializer
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def to_hash
    {
      user: {
        device_id: user.device_id,
        level: user.level,
        xp: user.xp,
        streak: user.streak,
        coins: user.coins,
        rest_days: user.rest_days,
        whisper: user.whisper,
        moko_mood: user.moko_mood,
        last_sync_at: user.last_sync_at
      },
      vfx_hints: VFXHintService.determine_hints(user),
      social_events: user.social_events.order(created_at: :desc).limit(5).map { |e| serialize_social_event(e) },
      sessions: user.sessions.map { |s| serialize_session(s) },
      moko_items: user.moko_items.map { |m| serialize_moko(m) },
      goal_nodes: user.goal_nodes.map { |g| serialize_goal(g) }
    }
  end

  private

  def serialize_session(session)
    {
      started_at: session.started_at,
      ended_at: session.ended_at,
      duration: session.duration,
      points: session.points,
      quality: session.quality
    }
  end

  def serialize_moko(moko)
    {
      item_id: moko.item_id,
      rarity: moko.rarity,
      unlocked_at: moko.unlocked_at
    }
  end

  def serialize_goal(goal)
    {
      title: goal.title,
      node_type: goal.node_type,
      estimate: goal.estimate,
      completed: goal.completed,
      completed_at: goal.completed_at
    }
  end

  def serialize_social_event(event)
    {
      type: event.event_type,
      metadata: event.metadata,
      occurred_at: event.created_at
    }
  end
end
