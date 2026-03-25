class Api::V1::AnalyticsController < ApplicationController
  def index
    render json: AnalyticsService.global_stats
  end

  def heatmap
    render json: AnalyticsService.world_heatmap
  end
end
