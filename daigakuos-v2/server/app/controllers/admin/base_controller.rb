class Admin::BaseController < ApplicationController
  # Simple HTTP Basic Auth for prototyping as requested
  # In a production app, we would use Devise or similar.
  http_basic_authenticate_with name: "admin", password: "moko_password"

  layout "admin"
end
