class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  # Called on POST /users/sign_in
  def respond_with(resource, _opts = {})
    render json: {
      status: { code: 200, message: "Logged in successfully." },
      data: resource
    }, status: :ok
  end

  # Called on DELETE /users/sign_out
  def respond_to_on_destroy(_resource = nil)
    # If the user is authenticated via the JWT in the header,
    # current_user will be populated automatically.
    if current_user
      render json: {
        status: 200,
        message: "Logged out successfully."
      }, status: :ok
    else
      render json: {
        status: 401,
        message: "No active session found."
      }, status: :unauthorized
    end
  end
end
