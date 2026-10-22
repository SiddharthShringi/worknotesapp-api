# spec/requests/api/v1/reports_spec.rb
require "rails_helper"

RSpec.describe "GET /api/v1/reports", type: :request do
  let(:user)    { create(:user, timezone: "Asia/Kolkata") }
  let(:project) { create(:project) }
  let(:headers) { auth_headers_for(user) }

  def get_report(date, as: headers)
    get "/api/v1/reports", params: { date: date }, headers: as
  end

  context "when not logged in" do
    it "returns 401" do
      get_report("2026-10-21", as: {})
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with a valid date" do
    before do
      zone = ActiveSupport::TimeZone["Asia/Kolkata"]
      create(:work_session, user: user, project: project,
             started_at: zone.parse("2026-10-21 09:00"),
             ended_at:   zone.parse("2026-10-21 10:00"))
    end

    it "returns 200 with the report shape the frontend needs" do
      get "/api/v1/reports", params: { date: "2026-10-21" }, headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include(
        "date", "total_duration", "total_sessions",
        "first_session_start", "last_session_end", "projects"
      )
      expect(json["total_sessions"]).to eq(1)
    end

    it "hands the service the current user and a parsed Date" do
      expect(DailyReportSummaryService)
        .to receive(:new).with(user, Date.new(2026, 10, 21)).and_call_original

      get_report("2026-10-21")
    end
  end

  context "when another user has sessions that day" do
    it "never includes them" do
      other = create(:user)
      create(:work_session, user: other, project: project,
             started_at: Time.zone.parse("2026-10-21 09:00"),
             ended_at:   Time.zone.parse("2026-10-21 10:00"))

      get_report("2026-10-21")

      expect(JSON.parse(response.body)["total_sessions"]).to eq(0)
    end
  end

  context "with a bad date" do
    it "returns 400 when date is missing" do
      get "/api/v1/reports", headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 400 when date is malformed" do
      get_report("banana")
      expect(response).to have_http_status(:bad_request)
    end
  end
end
