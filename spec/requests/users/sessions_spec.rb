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

  let(:headers) do
    { "Accept" => "application/json", "Content-Type" => "application/json" }
  end

  let(:auth_headers) do
    Devise::JWT::TestHelpers.auth_headers(headers, user)
  end

  describe "POST /users/sign_in" do
    context "when valid user credentials are provided" do
      before do
        post "/users/sign_in", params: params
      end

      it "returns http ok" do
        expect(response).to have_http_status(:ok)
      end

      it "returns success message" do
        data = JSON.parse(response.body)
        expect(data["message"]).to eq("Signed In Successfully")
      end
    end
  end

  describe "DELETE /users/sign_out" do
    context "when user has valid token" do
      it "returns http ok" do
        delete "/users/sign_out", headers: auth_headers
        expect(response).to have_http_status(:ok)
      end

      it "returns logout message" do
        delete "/users/sign_out", headers: auth_headers
        data = JSON.parse(response.body)
        expect(data["message"]).to eq("Logged out successfully.")
      end

      it "revokes the jti" do
        previous_jti = user.jti

        delete "/users/sign_out", headers: auth_headers

        user.reload
        expect(user.jti).not_to eq(previous_jti)
      end
    end
  end
end
