class Api::V1::ReportsController < ApplicationController
  def index
    @report = DailyReportSummaryService.new(current_user, Date.iso8601(report_params[:date])).call
  end

  private

  def report_params
    params.permit(:date)
  end
end
