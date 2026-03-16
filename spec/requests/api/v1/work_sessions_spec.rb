require "rails_helper"

RSpec.describe "WorkSessions API", type: :request do
  describe "GET /api/v1/work_sessions" do
    context "when the user is not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/work_sessions"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the user is authenticated" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      let(:project) { create(:project, user: user) }

      before do
        create_list(:work_session, 2, :completed, user: user, project: project)

        other_project = create(:project, user: other_user)
        create_list(:work_session, 3, :completed, user: other_user, project: other_project)

        get "/api/v1/work_sessions",
            headers: auth_headers_for(user)
      end

      it "returns successful response" do
        expect(response).to have_http_status(:ok)
      end

      it "returns only sessions belonging to the authenticated user" do
        json = JSON.parse(response.body)
        expect(json.size).to eq(2)
      end
    end

    context "when the user has no sessions" do
      let(:user) { create(:user) }

      before do
        get "/api/v1/work_sessions",
            headers: auth_headers_for(user)
      end

      it "returns an empty array" do
        json = JSON.parse(response.body)
        expect(json).to be_empty
      end
    end
  end

  describe "POST /api/v1/work_sessions" do
    let(:user) { create(:user) }
    let(:project) { create(:project, user: user) }

    let(:valid_params) do
      {
        work_session: {
          project_id: project.id,
          intent: "Implement timer feature"
        }
      }
    end

    context "with valid parameters" do
      before do
        post "/api/v1/work_sessions",
             params: valid_params,
             headers: auth_headers_for(user),
             as: :json
      end

      it "returns created status" do
        expect(response).to have_http_status(:created)
      end

      it "creates a new session" do
        json = JSON.parse(response.body)

        expect(json["intent"]).to eq(valid_params[:work_session][:intent])
        expect(json["project_id"]).to eq(project.id)
        expect(json["ended_at"]).to be_nil
      end
    end

    context "when user already has active session" do
      before do
        create(:work_session, user: user, project: project, ended_at: nil)

        post "/api/v1/work_sessions",
             params: valid_params,
             headers: auth_headers_for(user),
             as: :json
      end

      it "returns unprocessable content" do
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /api/v1/work_sessions/:id" do
    let(:user) { create(:user) }
    let(:project) { create(:project, user: user) }
    let!(:work_session) { create(:work_session, user: user, project: project) }

    context "when updating own session" do
      before do
        patch "/api/v1/work_sessions/#{work_session.id}",
              params: { work_session: { notes: "Updated notes" } },
              headers: auth_headers_for(user),
              as: :json
      end

      it "returns ok status" do
        expect(response).to have_http_status(:ok)
      end

      it "updates the session" do
        work_session.reload
        expect(work_session.notes).to eq("Updated notes")
      end
    end

    context "when updating another user's session" do
      let(:other_session) do
        other_user = create(:user)
        other_project = create(:project, user: other_user)
        create(:work_session, :completed, user: other_user, project: other_project)
      end

      before do
        patch "/api/v1/work_sessions/#{other_session.id}",
              params: { work_session: { notes: "Hack attempt" } },
              headers: auth_headers_for(user),
              as: :json
      end

      it "returns not found" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /api/v1/work_sessions/:id/stop" do
    let(:user) { create(:user) }
    let(:project) { create(:project, user: user) }
    let!(:work_session) { create(:work_session, user: user, project: project, ended_at: nil) }

    before do
      patch "/api/v1/work_sessions/#{work_session.id}/stop",
            params: { work_session: { notes: "Finished work" } },
            headers: auth_headers_for(user),
            as: :json
    end

    it "returns ok status" do
      expect(response).to have_http_status(:ok)
    end

    it "ends the session" do
      work_session.reload
      expect(work_session.ended_at).not_to be_nil
    end

    it "stores the notes" do
      work_session.reload
      expect(work_session.notes).to eq("Finished work")
    end
  end

  describe "DELETE /api/v1/work_sessions/:id" do
    let(:user) { create(:user) }
    let(:project) { create(:project, user: user) }
    let!(:work_session) { create(:work_session, user: user, project: project) }

    context "when deleting own session" do
      subject(:delete_request) do
        delete "/api/v1/work_sessions/#{work_session.id}",
              headers: auth_headers_for(user)
      end

      it "removes the session" do
        expect { delete_request }
          .to change { user.work_sessions.count }
          .by(-1)
      end

      it "returns no content status" do
        delete_request
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when deleting another user's session" do
      let(:other_session) do
        other_user = create(:user)
        other_project = create(:project, user: other_user)
        create(:work_session, :completed, user: other_user, project: other_project)
      end

      before do
        delete "/api/v1/work_sessions/#{other_session.id}",
              headers: auth_headers_for(user)
      end

      it "returns not found" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
