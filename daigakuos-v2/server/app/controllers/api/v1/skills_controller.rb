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
  
  def sharpen
    user = User.find_by!(device_id: params.require(:device_id))
    if user.sharpen!
      ActionCable.server.broadcast("chat_channel", {
        username: "SYSTEM",
        content: "🪨✨ 【#{user.username}】が砥石を使って武器を研ぎ澄ませたもこ！切れ味が最高になったもこ！",
        timestamp: Time.current.strftime("%H:%M")
      })
      
      render json: { 
        success: true, 
        message: "武器を研いだもこ！切れ味全快だもこ！✨",
        current_sharpness: user.current_sharpness,
        inventory: user.inventory
      }
    else
      render json: { success: false, error: "砥石がないもこ！補充するもこ！" }, status: :unprocessable_entity
    end
  end

  def heal
    user = User.find_by!(device_id: params.require(:device_id))
    if user.heal!
       ActionCable.server.broadcast("chat_channel", {
        username: "SYSTEM",
        content: "🧪✨ 【#{user.username}】が回復薬を飲んで体力を回復したもこ！",
        timestamp: Time.current.strftime("%H:%M")
      })
      render json: { 
        success: true, 
        message: "回復薬を飲んだもこ！体力が回復したもこ！✨",
        hp: user.hp,
        inventory: user.inventory
      }
    else
      render json: { success: false, error: "回復薬がないもこ！絶体絶命だもこ！" }, status: :unprocessable_entity
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
