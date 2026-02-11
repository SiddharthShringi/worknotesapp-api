# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def respond_with(resource, *args)
    Rails.logger.debug params.inspect
    Rails.logger.debug resource
    Rails.logger.debug sign_up_params.inspect
    Rails.logger.debug resource.errors.full_messages.inspect
    if resource.persisted?
      render json: {
        status: { code: 200, message: "Signed up successfully", data: resource }
      }, status: :ok
    else
      render json: {
        status: { message: "User could not be created!", errors: resource.errors.full_messages }
      }, status: :unprocessable_entity
    end
  end
end
