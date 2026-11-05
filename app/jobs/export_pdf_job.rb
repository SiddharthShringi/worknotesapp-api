
class ExportPdfJob
  include Sidekiq::Job

  sidekiq_options queue: "default", retry: 3

  sidekiq_retries_exhausted do |msg, error|
    Rails.logger.error(
      "ExportPdfJob failed: #{error.class} - #{error.message}"
    )

    export = Export.find_by(id: msg["args"].first)

    export&.update!(
      status: :failed,
      error_message: "We couldn't generate your PDF. Please try again."
    )
  end

  def perform(export_id)
    export = Export.find_by(id: export_id)
    return unless export
    return if export.completed?

    export.processing!

    date = parse_date(export.filters["date"])

    unless date
      export.update!(
        status: :failed,
        error_message: "Please choose a valid date."
      )
      return
    end

    pdf = generate_pdf(export.user, date)

    export.pdf.attach(
      io: StringIO.new(pdf),
      filename: "daily-report-#{date.iso8601}.pdf",
      content_type: "application/pdf"
    )

    export.update!(
      status: :completed,
      completed_at: Time.current,
      error_message: nil
    )
  end

  private

  def generate_pdf(user, date)
    Time.use_zone(user.timezone.presence || "UTC") do
      report = DailyReportSummaryService.new(user, date).call

      html = render_html(report, user)

      Grover.new(
        html,
        format: "A4",
        margin: {
          top: "18mm",
          bottom: "18mm",
          left: "14mm",
          right: "14mm"
        },
        print_background: true
      ).to_pdf
    end
  end

  def render_html(report, user)
    ActionController::Base.render(
      template: "api/v1/exports/pdf",
      layout: false,
      locals: {
        report: report,
        user: user,
        generated_at: Time.current
      }
    )
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
