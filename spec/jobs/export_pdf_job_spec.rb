require "rails_helper"

RSpec.describe ExportPdfJob, type: :job do
  let(:user) { create(:user, timezone: "Asia/Kolkata") }

  let(:export) do
    create(
      :export,
      user: user,
      filters: { date: "2026-11-16" },
      status: :pending
    )
  end

  let(:job) { described_class.new }

  describe "#perform" do
    context "when export does not exist" do
      it "returns without raising an error" do
        expect {
          job.perform(999999)
        }.not_to raise_error
      end
    end

    context "when export is already completed" do
      let(:export) do
        create(
          :export,
          user: user,
          filters: { date: "2026-11-16" },
          status: :completed
        )
      end

      it "does not generate the PDF again" do
        expect(job).not_to receive(:generate_pdf)

        job.perform(export.id)
      end

      it "does not change the export status" do
        job.perform(export.id)

        expect(export.reload).to be_completed
      end
    end

    context "when the export date is invalid" do
      let(:export) do
        create(
          :export,
          user: user,
          filters: { date: "invalid-date" },
          status: :pending
        )
      end

      it "marks the export as failed" do
        job.perform(export.id)

        expect(export.reload).to be_failed
      end

      it "sets an appropriate error message" do
        job.perform(export.id)

        expect(export.reload.error_message)
          .to eq("Please choose a valid date.")
      end

      it "does not attach a PDF" do
        job.perform(export.id)

        expect(export.reload.pdf).not_to be_attached
      end
    end

    context "when the export date is missing" do
      let(:export) do
        create(
          :export,
          user: user,
          filters: {},
          status: :pending
        )
      end

      it "marks the export as failed" do
        job.perform(export.id)

        expect(export.reload).to be_failed
        expect(export.reload.error_message)
          .to eq("Please choose a valid date.")
      end
    end

    context "when PDF generation succeeds" do
      let(:report_service) { double("DailyReportSummaryService") }
      let(:report) { double("DailyReport") }
      let(:html) { "<html><body>Daily Report</body></html>" }
      let(:pdf_content) { "%PDF-1.4 dummy pdf content" }
      let(:grover) { double("Grover", to_pdf: pdf_content) }

      let(:grover_options) do
        {
          format: "A4",
          margin: {
            top: "18mm",
            bottom: "18mm",
            left: "14mm",
            right: "14mm"
          },
          print_background: true
        }
      end

      before do
        allow(DailyReportSummaryService)
          .to receive(:new)
          .with(user, Date.new(2026, 11, 16))
          .and_return(report_service)

        allow(report_service)
          .to receive(:call)
          .and_return(report)

        allow(job)
          .to receive(:render_html)
          .with(report, user)
          .and_return(html)

        allow(Grover)
          .to receive(:new)
          .with(html, **grover_options)
          .and_return(grover)
      end

      it "generates the PDF using the report service" do
        expect(DailyReportSummaryService)
          .to receive(:new)
          .with(user, Date.new(2026, 11, 16))
          .and_return(report_service)

        job.perform(export.id)
      end

      it "generates the PDF using Grover" do
        expect(Grover)
          .to receive(:new)
          .with(html, **grover_options)
          .and_return(grover)

        job.perform(export.id)
      end

      it "attaches the generated PDF to the export" do
        job.perform(export.id)

        expect(export.reload.pdf).to be_attached
      end

      it "attaches the PDF with the correct filename" do
        job.perform(export.id)

        expect(export.reload.pdf.filename.to_s)
          .to eq("daily-report-2026-11-16.pdf")
      end

      it "attaches the PDF with the correct content type" do
        job.perform(export.id)

        expect(export.reload.pdf.content_type)
          .to eq("application/pdf")
      end

      it "stores the generated PDF content" do
        job.perform(export.id)

        expect(export.reload.pdf.download).to eq(pdf_content)
      end

      it "marks the export as completed" do
        job.perform(export.id)

        expect(export.reload).to be_completed
      end

      it "sets completed_at" do
        job.perform(export.id)

        expect(export.reload.completed_at).to be_present
      end

      it "clears the previous error message" do
        export.update!(error_message: "Previous error")

        job.perform(export.id)

        expect(export.reload.error_message).to be_nil
      end

      it "generates the report in the user's timezone" do
        expect(job).to receive(:render_html) do
          expect(Time.zone.name).to eq("Asia/Kolkata")
          html
        end

        job.perform(export.id)
      end

      it "falls back to UTC when the user's timezone is blank" do
        user.update_column(:timezone, "")

        expect(job).to receive(:render_html) do
          expect(Time.zone.name).to eq("UTC")
          html
        end

        job.perform(export.id)
      end
    end

    context "when PDF generation fails" do
      before do
        allow(job)
          .to receive(:generate_pdf)
          .and_raise(StandardError, "PDF generation failed")
      end

      it "propagates the exception" do
        expect {
          job.perform(export.id)
        }.to raise_error(StandardError, "PDF generation failed")
      end

      it "leaves the export in processing status" do
        expect {
          job.perform(export.id)
        }.to raise_error(StandardError)

        expect(export.reload).to be_processing
      end

      it "does not attach a PDF" do
        expect {
          job.perform(export.id)
        }.to raise_error(StandardError)

        expect(export.reload.pdf).not_to be_attached
      end
    end
  end

  describe ".mark_as_failed" do
    it "marks the export as failed" do
      described_class.mark_as_failed(export.id)

      expect(export.reload).to be_failed
    end

    it "sets the appropriate error message" do
      described_class.mark_as_failed(export.id)

      expect(export.reload.error_message).to eq(
        "We couldn't generate your PDF. Please try again."
      )
    end

    context "when export does not exist" do
      it "returns without raising an error" do
        expect {
          described_class.mark_as_failed(999999)
        }.not_to raise_error
      end
    end
  end
end
