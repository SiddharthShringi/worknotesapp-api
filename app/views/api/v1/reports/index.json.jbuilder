puts @report, "++++++++++++"

json.extract! @report, :date, :total_duration, :total_sessions, :first_session_start, :last_session_end
json.projects @report[:projects] do |project|
  json.extract! project, :id, :color, :name, :duration
  json.sessions project[:sessions] do |session|
    json.extract! session, :id, :intent, :started_at, :ended_at
    json.project session.project, :name, :color
    json.duration session.duration
    json.notes session.notes
  end
end
