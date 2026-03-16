class ApplicationController < ActionController::API
  # include Devise::Controllers::Helpers
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!

  # use it later if required
  # rescue_from ActiveRecord::RecordNotFound do
  #   render json: { errors: [ "Resource not found" ] }, status: :not_found
  # end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name ])
  end
end
