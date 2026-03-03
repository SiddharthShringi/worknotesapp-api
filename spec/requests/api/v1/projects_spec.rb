require "rails_helper"
RSpec.describe "Projects API", type: :request do
  describe "GET /api/v1/projects" do
    context "when the user is not authenticated" do
      it "returns an unauthorized status" do
        get "/api/v1/projects"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the user is authenticated" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }

      before do
        create_list(:project, 2, user: user)
        create_list(:project, 3, user: other_user)

        get "/api/v1/projects",
            headers: auth_headers_for(user)
      end

      it "returns successful response" do
        expect(response).to have_http_status(:ok)
      end

      it "returns only projects belonging to the authenticated user" do
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(2)
      end
    end

    context "when the user has no projects" do
      let(:user) { create(:user) }

      before do
        get "/api/v1/projects",
            headers: auth_headers_for(user)
      end

      it "returns an empty array" do
        json_response = JSON.parse(response.body)
        expect(json_response).to be_empty
      end
    end
  end

  describe "POST /api/v1/projects for authenticated user" do
    let(:valid_params) do
      {
        project: {
          name: "New Project",
          description: "Project description",
          color: "blue"
        }
      }
    end

    let(:user) { create(:user) }

    context "with valid parameters" do
      before do
        post "/api/v1/projects",
              params: valid_params,
              as: :json,
              headers: auth_headers_for(user)
      end

      it "returns a created status" do
        expect(response).to have_http_status(:created)
      end

      it "creates a new project for the user" do
        json_response = JSON.parse(response.body)
        expect(json_response["user_id"]).to eq(user.id)
      end

      it "returns the created project in the response" do
        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq(valid_params[:project][:name])
        expect(json_response["description"]).to eq(valid_params[:project][:description])
        expect(json_response["color"]).to eq(valid_params[:project][:color])
        expect(json_response["archived"]).to be(false)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          project: {
            name: "",
            color: ""
          }
        }
      end

      before do
        post "/api/v1/projects",
              params: invalid_params,
              as: :json,
              headers: auth_headers_for(user)
      end

      it "returns an unprocessable content status" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns error messages in the response" do
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to have_key("name")
        expect(json_response["errors"]).to have_key("color")
      end
    end

    context "with duplicate name for same user" do
      before do
        create(:project, name: "Duplicate Project", user: user)

        post "/api/v1/projects",
            params: {
              project: {
                name: "Duplicate Project",
                color: "red"
              }
            },
            headers: auth_headers_for(user),
            as: :json
      end

      it "returns unprocessable content" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns name validation error" do
        json = JSON.parse(response.body)
        expect(json["errors"]).to have_key("name")
      end
    end
  end

  describe "PATCH /api/v1/projects/:id" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:project) { create(:project, user: user) }

    context "when authenticated user updates own project with valid params" do
      let(:update_params) do
        {
          project: {
            name: "Updated Name",
            description: "Updated description",
            color: "red"
          }
        }
      end

      before do
        patch "/api/v1/projects/#{project.id}",
              params: update_params,
              headers: auth_headers_for(user),
              as: :json
      end

      it "returns ok status" do
        expect(response).to have_http_status(:ok)
      end

      it "updates the project in database" do
        project.reload
        expect(project.name).to eq("Updated Name")
        expect(project.description).to eq("Updated description")
        expect(project.color).to eq("red")
      end
    end

    context "when params are invalid" do
      before do
        patch "/api/v1/projects/#{project.id}",
              params: { project: { name: "" } },
              headers: auth_headers_for(user),
              as: :json
      end

      it "returns unprocessable content" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns validation errors" do
        json = JSON.parse(response.body)
        expect(json["errors"]).to have_key("name")
      end
    end

    context "when user tries to update someone else's project" do
      let!(:other_project) { create(:project, user: other_user) }

      before do
        patch "/api/v1/projects/#{other_project.id}",
              params: { project: { name: "Hacked" } },
              headers: auth_headers_for(user),
              as: :json
      end

      it "returns not found or forbidden" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/projects/:id" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:project) { create(:project, user: user) }

    context "when authenticated user deletes own project" do
      it "removes project from database" do
        expect {
          delete "/api/v1/projects/#{project.id}",
                headers: auth_headers_for(user)
        }.to change { user.projects.count }.by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context "when user tries to delete someone else's project" do
      let!(:other_project) { create(:project, user: other_user) }

      before do
        delete "/api/v1/projects/#{other_project.id}",
              headers: auth_headers_for(user)
      end

      it "returns not found or forbidden" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is not authenticated" do
      before do
        delete "/api/v1/projects/#{project.id}"
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
