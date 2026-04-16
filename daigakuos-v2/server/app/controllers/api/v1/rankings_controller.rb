class Api::V1::RankingsController < ApplicationController
  def index
    render json: RankingService.top_100
  end
end
