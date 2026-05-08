class Api::V1::ProfilesController < ApplicationController
  def update
    if current_user.update(user_params)
      render json: current_user, status: :ok
    else
      render json: { errors: current_user.errors.to_hash }, status: :unprocessabel_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :timezone)
  end
end
