
require "rails_helper"

RSpec.describe "Api::V1::Exports", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { auth_headers_for(user) }

  let(:valid_params) do
    {
      export: {
        date: "2026-11-16"
      }
    }
  end

  before do
    ExportPdfJob.clear
  end

  describe "POST /api/v1/exports" do
    context "when the date is valid" do
      it "creates a new export" do
        expect {
          post api_v1_exports_path,
            params: valid_params,
            headers: auth_headers
        }.to change(user.exports, :count).by(1)

        expect(response).to have_http_status(:accepted)

        export = user.exports.last

        expect(export.filters).to eq(
          "date" => "2026-11-16"
        )

        expect(export).to be_pending
      end

      it "enqueues an ExportPdfJob with the export ID" do
        expect {
          post api_v1_exports_path,
            params: valid_params,
            headers: auth_headers
        }.to change(ExportPdfJob.jobs, :size).by(1)

        export = user.exports.last

        expect(ExportPdfJob.jobs.last["args"]).to eq([ export.id ])
      end

      it "returns the created export in the response" do
        post api_v1_exports_path,
          params: valid_params,
          headers: auth_headers

        export = user.exports.last

        expect(response).to have_http_status(:accepted)

        expect(response.parsed_body).to eq(
          "id" => export.id,
          "status" => "pending",
          "error_message" => nil,
          "download_url" => nil
        )
      end
    end

    context "when a pending export already exists for the date" do
      let!(:existing_export) do
        create(
          :export,
          user: user,
          filters: { date: "2026-11-16" },
          status: :pending
        )
      end

      it "returns the existing export" do
        expect {
          post api_v1_exports_path,
            params: valid_params,
            headers: auth_headers
        }.not_to change(user.exports, :count)

        expect(response).to have_http_status(:ok)

        expect(response.parsed_body["id"]).to eq(existing_export.id)
        expect(response.parsed_body["status"]).to eq("pending")
      end

      it "does not enqueue another PDF job" do
        expect {
          post api_v1_exports_path,
            params: valid_params,
            headers: auth_headers
        }.not_to change(ExportPdfJob.jobs, :size)
      end
    end

    context "when a processing export already exists for the date" do
      let!(:existing_export) do
        create(
          :export,
          user: user,
          filters: { date: "2026-11-16" },
          status: :processing
        )
      end

      it "returns the existing export" do
        expect {
          post api_v1_exports_path,
            params: valid_params,
            headers: auth_headers
        }.not_to change(user.exports, :count)

        expect(response).to have_http_status(:ok)

        expect(response.parsed_body["id"]).to eq(existing_export.id)
        expect(response.parsed_body["status"]).to eq("processing")
      end

      it "does not enqueue another PDF job" do
        expect {
          post api_v1_exports_path,
            params: valid_params,
            headers: auth_headers
        }.not_to change(ExportPdfJob.jobs, :size)
      end
    end

    context "when a failed export already exists for the date" do
      let!(:existing_export) do
        create(
          :export,
          user: user,
          filters: { date: "2026-11-16" },
          status: :failed
        )
      end

      it "creates a new export" do
        expect {
          post api_v1_exports_path,
            params: valid_params,
            headers: auth_headers
        }.to change(user.exports, :count).by(1)

        expect(response).to have_http_status(:accepted)
        expect(user.exports.order(:created_at).last).to be_pending
      end

      it "enqueues a new PDF job" do
        expect {
          post api_v1_exports_path,
            params: valid_params,
            headers: auth_headers
        }.to change(ExportPdfJob.jobs, :size).by(1)
      end
    end

    context "when an export exists for another date" do
      let!(:existing_export) do
        create(
          :export,
          user: user,
          filters: { date: "2026-11-15" },
          status: :pending
        )
      end

      it "creates a new export" do
        expect {
          post api_v1_exports_path,
            params: valid_params,
            headers: auth_headers
        }.to change(user.exports, :count).by(1)

        expect(response).to have_http_status(:accepted)
      end
    end

    context "when another user has an active export for the same date" do
      let(:other_user) { create(:user) }

      let!(:other_export) do
        create(
          :export,
          user: other_user,
          filters: { date: "2026-11-16" },
          status: :pending
        )
      end

      it "creates a separate export for the current user" do
        expect {
          post api_v1_exports_path,
            params: valid_params,
            headers: auth_headers
        }.to change(user.exports, :count).by(1)

        expect(response).to have_http_status(:accepted)
        expect(user.exports.last.id).not_to eq(other_export.id)
      end
    end

    context "when the date is invalid" do
      it "returns unprocessable entity" do
        post api_v1_exports_path,
          params: { export: { date: "16-11-2026" } },
          headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create an export" do
        expect {
          post api_v1_exports_path,
            params: { export: { date: "2026-02-30" } },
            headers: auth_headers
        }.not_to change(user.exports, :count)
      end

      it "does not enqueue a PDF job" do
        expect {
          post api_v1_exports_path,
            params: { export: { date: "invalid-date" } },
            headers: auth_headers
        }.not_to change(ExportPdfJob.jobs, :size)
      end
    end

    context "when the date is missing" do
      it "returns unprocessable entity" do
        post api_v1_exports_path,
          params: { export: {} },
          headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when export parameters are missing" do
      it "returns unprocessable entity" do
        post api_v1_exports_path,
          headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /api/v1/exports/:id" do
    let!(:export) do
      create(
        :export,
        user: user,
        filters: { date: "2026-11-16" }
      )
    end

    context "when requesting own export" do
      it "returns the export" do
        get api_v1_export_path(export),
          headers: auth_headers

        expect(response).to have_http_status(:ok)

        expect(response.parsed_body).to eq(
          "id" => export.id,
          "status" => "pending",
          "error_message" => nil,
          "download_url" => nil
        )
      end
    end

    context "when requesting another user's export" do
      let(:other_user) { create(:user) }

      let!(:other_export) do
        create(
          :export,
          user: other_user,
          filters: { date: "2026-11-16" }
        )
      end

      it "returns not found" do
        get api_v1_export_path(other_export),
          headers: auth_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when export does not exist" do
      it "returns not found" do
        get api_v1_export_path(id: 999999),
          headers: auth_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "authentication" do
    it "requires authentication for POST /api/v1/exports" do
      post api_v1_exports_path,
        params: valid_params

      expect(response).to have_http_status(:unauthorized)
    end

    it "requires authentication for GET /api/v1/exports/:id" do
      get api_v1_export_path(id: 1)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
