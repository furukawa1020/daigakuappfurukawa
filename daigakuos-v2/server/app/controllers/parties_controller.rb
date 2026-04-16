class PartiesController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def create
    user = User.find_by(device_id: params[:device_id])
    return render json: { error: "User not found" }, status: :not_found unless user
    
    party = Party.create!(
      name: params[:name],
      leader_id: user.id,
      passcode: params[:passcode]
    )
    
    PartyMembership.create!(user: user, party: party)
    
    render json: { success: true, party: party_json(party) }
  end

  def join
    user = User.find_by(device_id: params[:device_id])
    party = Party.find_by(name: params[:name])
    
    return render json: { error: "Party/User not found" }, status: :not_found unless user && party
    return render json: { error: "Invalid passcode" }, status: :forbidden if party.passcode.present? && party.passcode != params[:passcode]
    
    # Leave current party if any
    user.party_membership&.destroy
    
    PartyMembership.create!(user: user, party: party)
    
    ActionCable.server.broadcast("chat_global", {
      username: "SYSTEM",
      content: "#{user.username} がパーティ 「#{party.name}」 に参加したもこ！🤝",
      timestamp: Time.current.strftime("%H:%M")
    })
    
    render json: { success: true, party: party_json(party) }
  end

  def leave
    user = User.find_by(device_id: params[:device_id])
    return render json: { error: "User not found" }, status: :not_found unless user
    
    user.party_membership&.destroy
    render json: { success: true }
  end

  def show
    user = User.find_by(device_id: params[:device_id])
    party = user&.party
    
    if party
      render json: { party: party_json(party) }
    else
      render json: { party: nil }
    end
  end

  private

  def party_json(party)
    {
      id: party.id,
      name: party.name,
      leader_id: party.leader_id,
      members: party.users.map { |u| { username: u.username, moko_mood: u.moko_mood, level: u.level } }
    }
  end
end
