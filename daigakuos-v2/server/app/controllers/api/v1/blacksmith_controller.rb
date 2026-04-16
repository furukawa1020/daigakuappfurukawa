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
