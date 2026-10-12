class DailyReportSummaryService
  def initialize(user, date)
    @user = user
    @date = date
  end

  def call
    generate_report
  end

  def generate_report
    Time.use_zone(@user.timezone) do
      work_sessions = @user.work_sessions.includes(:project).where(started_at: @date.all_day).order(:started_at).to_a
      projects = work_sessions.map(&:project).uniq
      {
        date: @date,
        total_duration: work_sessions.sum(&:duration),
        total_sessions: work_sessions.count,
        first_session_start: work_sessions.first&.started_at,
        last_session_end: work_sessions.last&.ended_at,
        projects: projects.map do |project|
          sessions = work_sessions.select { |ws| ws.project_id == project.id }
          {
            id: project.id,
            color: project.color,
            name: project.name,
            duration: sessions.sum(&:duration),
            sessions: sessions
          }
        end
      }
    end
  end
end
