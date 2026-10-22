class Api::V1::ReportsController < ApplicationController
  def index
     date = parse_date
    return render json: { error: "date must be YYYY-MM-DD" }, status: :bad_request unless date

    @report = DailyReportSummaryService.new(current_user, date).call
  end

  private

  def parse_date
    Date.iso8601(report_params[:date].to_s)
  rescue Date::Error
    nil
  end

  def report_params
    params.permit(:date)
  end
end
