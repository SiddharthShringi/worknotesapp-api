# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  skip_before_action :authenticate_user!

  private

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def respond_with(resource, *args)
    if resource.persisted?
      render json: { user: {
        id: resource.id,
        email: resource.email,
        first_name: resource.first_name,
        last_name: resource.last_name,
        timezone: resource.timezone
      }, message: "Signed up Successfully" }, status: :created
    else
      render json: {
        errors: resource.errors.to_hash,
        message: "User could not be created!" }, status: :unprocessable_content
    end
  end

  protected

  def configure_permitted_parameters
    # For sign up, permit first_name, last_name, and username
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])

    # If you allow users to update their profile later:
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :timezone ])
  end
end
