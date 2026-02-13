
require "rails_helper"
require "devise/jwt/test_helpers"

RSpec.describe "sessions", type: :request do
  let(:user) { create(:user) }
  let(:params) do
    {
      user: {
        email: user.email,
        password: user.password

      }
    }
  end

  describe "POST /users/sign_in" do
    context "when valid user credentials are provided" do
      it "Signin the user" do
        post "/users/sign_in", params: params
        data = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(data["message"]).to eq("Signed In Successfully")
      end
    end
  end

  describe "DELETE /users/sign_out" do
    context "user with valid token" do
      it "Sign out the user" do
      # Create valid headers for the user using the helper
      headers = { "Accept" => "application/json", "Content-Type" => "application/json" }
      auth_headers = Devise::JWT::TestHelpers.auth_headers(headers, user)

      user_previous_jti = user.jti

      # Perform the Sign out using the generated headers
      delete "/users/sign_out", headers: auth_headers

      expect(response).to have_http_status(:ok)

      data = JSON.parse(response.body)
      expect(data["message"]).to eq("Logged out successfully.")

      # Verify JTI Revocation
      user.reload
      expect(user.jti).not_to eq(user_previous_jti)
      end
    end
  end
end
