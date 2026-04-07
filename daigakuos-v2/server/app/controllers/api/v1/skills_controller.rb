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

  def eat
    user = User.find_by!(device_id: params.require(:device_id))
    result = CanteenService.eat!(user, params.require(:meal_id))
    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  end

  def combine
    user = User.find_by!(device_id: params.require(:device_id))
    result = CombinationService.combine!(user, params.require(:item_id))
    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  end

  def use_item
    user = User.find_by!(device_id: params.require(:device_id))
    item_id = params.require(:item_id)
    
    case item_id
    when 'antidote'
      if user.consume_item!('antidote')
        status = user.status_effects || {}
        status.delete('poisoned')
        user.update!(status_effects: status)
        render json: { success: true, message: '毒を洗い流したもこ！✨' }
      else
        render json: { success: false, error: '解毒薬がないもこ！' }, status: :unprocessable_entity
      end
    when 'energy_drink'
       if user.consume_item!('energy_drink')
        user.update!(stamina: user.max_stamina)
        render json: { success: true, message: 'スタミナ全快だもこ！⚡' }
      else
        render json: { success: false, error: 'エナジードリンクがないもこ！' }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: '使い方がわからないもこ...' }, status: :bad_request
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
