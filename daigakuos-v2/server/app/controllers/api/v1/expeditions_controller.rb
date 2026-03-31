class Api::V1::ExpeditionsController < ApplicationController
  def start_quest
    user = User.find_by(device_id: params[:device_id])
    return render json: { error: "User not found" }, status: :not_found unless user

    result = ExpeditionEngineService.start_quest!(user, params[:quest_type])
    if result[:success]
      render json: { message: "Quest started!", user: UserSerializer.new(user).as_json }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def abandon_quest
    user = User.find_by(device_id: params[:device_id])
    return render json: { error: "User not found" }, status: :not_found unless user

    exp = user.moko_expeditions.active.first
    if exp
      exp.abandon! if exp.respond_to?(:abandon!)
      exp.update!(status: 'abandoned') unless exp.respond_to?(:abandon!)
      render json: { message: "Quest abandoned.", user: UserSerializer.new(user).as_json }
    else
      render json: { error: "No active quest found." }, status: :unprocessable_entity
    end
  end
end
