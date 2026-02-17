class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  # Called on POST /users/sign_in
  def respond_with(resource, _opts = {})
    render json: { user: resource, message: "Signed In Successfully" }, status: :ok
  end

  # Called on DELETE /users/sign_out
  def respond_to_on_destroy(_resource = nil)
    # If the user is authenticated via the JWT in the header,
    # current_user will be populated automatically.
    if current_user
      render json: {
        message: "Logged out successfully."
      }, status: :ok
    else
      render json: {
        message: "No active session found."
      }, status: :unauthorized
    end
  end
end
