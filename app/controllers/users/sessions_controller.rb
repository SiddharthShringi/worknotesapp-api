# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, optinos = {})
    render json: {
      status: :ok,
      data: {
        code: 200,
        message: "User Signed in successfully!",
        data: resource
      }
    }
  end
end
