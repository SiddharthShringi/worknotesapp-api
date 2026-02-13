require "rails_helper"

RSpec.describe "Registration", type: :request do
  let(:user) { build(:user) }
  let(:params) do
    {
      user: {
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        password: user.password,
        password_confirmation: user.password_confirmation
      }
    }
  end

  describe "POST /users" do
    context "when valid user credentials are provided" do
      it "register the user" do
        post "/users", params: params
        data = JSON.parse(response.body)
        expect(response).to have_http_status(:created)
        expect(data["message"]).to eq("Signed up Successfully")
      end
    end
  end
end
