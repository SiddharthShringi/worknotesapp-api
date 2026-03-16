class Api::V1::WorkSessionsController < ApplicationController
  before_action :set_work_session, only: [ :update, :destroy, :stop ]

  def index
    work_sessions = current_user.work_sessions
                                .includes(:project)
                                .order(started_at: :desc)

    render json: work_sessions, status: :ok
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
    if @work_session.update(update_params)
      render json: @work_session, status: :ok
    else
      render json: { errors: @work_session.errors.to_hash }, status: :unprocessable_content
    end
  end

  def stop
    if @work_session.ended_at.present?
      return render json: { error: "Session already ended" }, status: :unprocessable_content
    end

    if @work_session.update(notes: stop_params[:notes], ended_at: Time.current)
      render json: @work_session, status: :ok
    else
      render json: { errors: @work_session.errors.to_hash }, status: :unprocessable_content
    end
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
    params.require(:work_session).permit(:project_id, :intent)
  end

  def update_params
    params.require(:work_session).permit(:intent, :notes)
  end

  def stop_params
    params.require(:work_session).permit(:notes)
  end
end
