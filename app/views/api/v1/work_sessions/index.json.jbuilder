json.array! @work_sessions do |work_session|
  json.extract! work_session, :id, :intent, :started_at, :ended_at
  json.project work_session.project, :name, :color
  json.duration work_session.duration
  json.notes work_session.notes
end
