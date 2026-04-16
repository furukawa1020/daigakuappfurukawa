class Api::V1::AlchemyController < ApplicationController
  def craft_upgrade
    user = User.find_by(device_id: params[:device_id])
    return render json: { error: "User not found" }, status: :not_found unless user

    result = MokoAlchemyService.craft_upgrade!(user, params[:moko_item_id])
    if result[:success]
      render json: { message: result[:message], user: UserSerializer.new(user).as_json }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end
end
