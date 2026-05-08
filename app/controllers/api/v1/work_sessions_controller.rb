class Api::V1::WorkSessionsController < ApplicationController
  before_action :set_work_session, only: [ :update, :destroy, :stop ]

  def index
    @grouped_work_sessions = current_user.work_sessions
                                .includes(:project)
                                .order(started_at: :desc)
                                .group_by { |session|   session.started_at.in_time_zone("Asia/Kolkata").to_date }
  end

  def create
    project = current_user.projects.find(work_session_params[:project_id])

    work_session = current_user.work_sessions.build(
      project: project,
      intent: work_session_params[:intent],
      started_at: Time.current
    )

    if work_session.save
      render json: work_session, status: :created
    else
      render json: { errors: work_session.errors.to_hash }, status: :unprocessable_content
    end
  end

  def update
    if @work_session.update(work_session_params)
      render json: @work_session, status: :ok
    else
      render json: { errors: @work_session.errors.to_hash }, status: :unprocessable_content
    end
  end

  def stop
    if @work_session.ended_at.present?
      return render json: { error: "Session already ended" }, status: :unprocessable_content
    end

    if @work_session.update(ended_at: Time.current)
      render json: @work_session, status: :ok
    else
      render json: { errors: @work_session.errors.to_hash }, status: :unprocessable_content
    end
  end

  def active
    active_work_session = current_user.work_sessions.find_by(ended_at: nil)

    render json: active_work_session, status: :ok
  end

  def destroy
    @work_session.destroy
    head :no_content
  end

  private

  def set_work_session
    @work_session = current_user.work_sessions.find(params[:id])
  end

  def work_session_params
    params.require(:work_session).permit(:project_id, :intent, :notes)
  end
end
