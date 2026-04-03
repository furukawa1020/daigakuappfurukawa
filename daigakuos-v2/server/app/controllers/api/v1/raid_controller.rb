class Api::V1::RaidController < ApplicationController
  def status
    # Ensure current raid status is fresh
    GlobalRaidLifecycleJob.perform_now
    
    raid = GlobalRaid.active.first
    
    if raid
      render json: {
        active: true,
        raid: {
          id: raid.id,
          title: raid.title,
          current_hp: raid.current_hp,
          max_hp: raid.max_hp,
          health_percentage: raid.health_percentage,
          ends_at: raid.ends_at,
          participants_count: raid.participants_data.keys.size,
          top_contributors: raid.leaderboard(5)
        }
      }
    else
      render json: { active: false, message: "現在、アクティブなレイドボスはいません。" }
    end
  end
end
