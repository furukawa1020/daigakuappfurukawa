# app/controllers/api/v1/quests_controller.rb
class Api::V1::QuestsController < ApplicationController
  def index
    user = User.find_by!(device_id: params[:device_id])
    available_monsters = PartBreakService::MONSTERS.keys
    
    # Generate random available quests if none exist
    if user.hunting_quests.available.empty?
      available_monsters.each do |monster|
        user.hunting_quests.create!(
          target_monster: monster,
          difficulty: PartBreakService::MONSTERS[monster][:difficulty],
          required_minutes: 60 * PartBreakService::MONSTERS[monster][:difficulty],
          status: :available
        )
      end
    end
    
    render json: {
      active_quest: user.hunting_quests.active.first,
      available_quests: user.hunting_quests.available,
      completed_quests: user.hunting_quests.completed.limit(5)
    }
  end

  def start
    user = User.find_by!(device_id: params[:device_id])
    quest = user.hunting_quests.find(params[:id])
    
    # Cancel other active quests
    user.hunting_quests.active.update_all(status: :available)
    quest.active!
    
    render json: { success: true, quest: quest }
  end
end

# app/controllers/api/v1/blacksmith_controller.rb
class Api::V1::BlacksmithController < ApplicationController
  def index
    user = User.find_by!(device_id: params[:device_id])
    render json: {
      inventory: user.inventory || {},
      recipes: BlacksmithService::RECIPES,
      passive_buffs: user.passive_buffs || {}
    }
  end

  def craft
    user = User.find_by!(device_id: params[:device_id])
    result = BlacksmithService.craft!(user, params[:item_id])
    
    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  end
end
