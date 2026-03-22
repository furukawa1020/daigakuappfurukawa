class Api::V1::MokosController < ApplicationController
  skip_before_action :authenticate_request, only: [:index]

  def index
    templates = MokoTemplate.order(:phase, :required_level)
    render json: { success: true, payload: templates.as_json(except: [:id, :created_at, :updated_at]) }, status: :ok
  end
end
