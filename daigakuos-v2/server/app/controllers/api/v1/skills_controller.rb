class Api::V1::SkillsController < ApplicationController
  def use
    user = User.find_by!(device_id: params.require(:device_id))
    
    result = RoleSkillService.use_skill!(user)
    
    if result[:success]
      render json: result, status: :ok
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end
  
  def status
    user = User.find_by!(device_id: params.require(:device_id))
    render json: { 
      can_use: user.can_use_skill?,
      cooldown: user.skill_cooldown_remaining,
      role: user.role
    }
  end
end
