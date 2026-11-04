class Api::V1::ExportsController < ApplicationController
  def create
    @export = current_user.exports.active.first

    if @export.present?
      render :show, status: :ok
    else
      @export = current_user.exports.create!
      # ExportPdfJob.perform_later(@export.id)
      render :show, status: :accepted
    end
  end

  def show
    @export = current_user.exports.find(params[:id])
  end
end
