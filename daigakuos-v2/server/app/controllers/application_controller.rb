class ApplicationController < ActionController::API
  before_action :authenticate_request

  # --- Global Error Handling ---
  rescue_from StandardError, with: :render_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def authenticate_request
    auth_header = request.headers['Authorization']
    token = auth_header.split(' ').last if auth_header.present?
    
    unless token && valid_token?(token)
      render json: { success: false, error: "Unauthorized: Invalid or missing Bearer token" }, status: :unauthorized
    end
  end

  def valid_token?(token)
    # In production, this would use JWT.decode. Here we accept a static token to demonstrate proper request authorization architecture.
    token == "daigaku_secret_token"
  end

  def render_internal_error(exception)
    Rails.logger.error("Internal Error: #{exception.message}")
    Rails.logger.error(exception.backtrace.first(10).join("\n"))
    render json: { success: false, error: "Internal Server Error" }, status: :internal_server_error
  end

  def render_not_found(exception)
    render json: { success: false, error: exception.message }, status: :not_found
  end

  def render_unprocessable_entity(exception)
    render json: { success: false, errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

  def render_bad_request(exception)
    render json: { success: false, error: "Missing required parameter: #{exception.param}" }, status: :bad_request
  end
end
