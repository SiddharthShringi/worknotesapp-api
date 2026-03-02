require "rails_helper"
RSpec.describe "Projects API", type: :request do
  context "when the user is not authenticated" do
    it "returns an unauthorized status" do
      get "/api/v1/projects"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
