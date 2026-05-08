json.array! @grouped_work_sessions do |date, work_sessions|
  json.date date
  json.total_duration work_sessions.sum(&:duration)
  json.sessions work_sessions do |session|
    json.extract! session, :id, :intent, :started_at, :ended_at
    json.project session.project, :name, :color
    json.duration session.duration
    json.notes session.notes
  end
end
