
class ExportsController < ApplicationController
  before_action :authenticate_user!

  # POST /exports
  def create
    date = parse_date(export_params[:date])
    return head :unprocessable_entity unless date

    @export = find_active_export(date)

    if @export
      render :show, status: :ok
    else
      @export = create_export(date)
      ExportPdfJob.perform_async(@export.id)

      render :show, status: :accepted
    end
  end

  # GET /exports/:id
  def show
    @export = current_user.exports.find(params[:id])
  end

  private

  def export_params
    params.fetch(:export, ActionController::Parameters.new).permit(:date)
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end

  def find_active_export(date)
    filters = { "date" => date.iso8601 }

    current_user.exports.active.find_by(
      "filters @> ?::jsonb",
      filters.to_json
    )
  end

  def create_export(date)
    current_user.exports.create!(
      filters: { "date" => date.iso8601 }
    )
  end
end
