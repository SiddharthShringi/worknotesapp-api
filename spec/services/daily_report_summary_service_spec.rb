# spec/services/daily_report_summary_service_spec.rb
require "rails_helper"

RSpec.describe DailyReportSummaryService do
  subject(:report) { described_class.new(user, date).call }

  let(:user)    { create(:user, timezone: "Asia/Kolkata") }
  let(:date)    { Date.new(2026, 10, 21) }
  let(:project_a) { create(:project, name: "A") }
  let(:project_b) { create(:project, name: "B") }


  # helper so each test reads like a story
  def session_at(start_str, end_str, project:, owner: user)
    zone = ActiveSupport::TimeZone["Asia/Kolkata"]
    create(:work_session,
           user: owner,
           project: project,
           started_at: zone.parse(start_str),
           ended_at: zone.parse(end_str))
  end

  context "when there are no sessions" do
    it "returns an empty, zeroed report" do
      expect(report).to include(
        date: date,
        total_duration: 0,
        total_sessions: 0,
        first_session_start: nil,
        last_session_end: nil,
        projects: []
      )
    end
  end

  context "with sessions across two projects" do
    before do
      session_at("2026-10-21 14:00", "2026-10-21 15:00", project: project_b) # 1h
      session_at("2026-10-21 09:00", "2026-10-21 10:30", project: project_a) # 1.5h
      session_at("2026-10-21 11:00", "2026-10-21 12:00", project: project_a) # 1h
    end

    it "totals everything" do
      expect(report[:total_sessions]).to eq(3)
      expect(report[:total_duration]).to eq(3.5.hours)
    end

    it "reports first start and last end in order of time" do
      expect(report[:first_session_start]).to eq(Time.find_zone("Asia/Kolkata").parse("2026-10-21 09:00"))
      expect(report[:last_session_end]).to eq(Time.find_zone("Asia/Kolkata").parse("2026-10-21 15:00"))
    end

    it "groups sessions by project with per-project durations" do
      a = report[:projects].find { |p| p[:id] == project_a.id }
      b = report[:projects].find { |p| p[:id] == project_b.id }

      expect(a[:duration]).to eq(2.5.hours)
      expect(a[:sessions].size).to eq(2)
      expect(b[:duration]).to eq(1.hour)
    end
  end

  context "when other data exists that should be ignored" do
    it "ignores other days and other users" do
      session_at("2026-10-20 23:59", "2026-10-21 00:30", project: project_a) # started yesterday
      session_at("2026-10-22 00:00", "2026-10-22 01:00", project: project_a) # starts tomorrow
      session_at("2026-10-21 10:00", "2026-10-21 11:00", project: project_a, owner: create(:user))

      expect(report[:total_sessions]).to eq(0)
    end
  end

  context "when sessions sit at the edges of the user's day" do
    it "includes 23:59 and 00:00 in the user's day, not UTC's day" do
      session_at("2026-10-21 00:00", "2026-10-21 00:30", project: project_a)
      session_at("2026-10-21 23:30", "2026-10-21 23:59", project: project_a)

      expect(report[:total_sessions]).to eq(2)
    end
  end

  context "when a session is still running (ended_at is nil)" do
    it "does not blow up" do
      zone = ActiveSupport::TimeZone["Asia/Kolkata"]
      create(:work_session, user: user, project: project_a,
             started_at: zone.parse("2026-10-21 09:00"), ended_at: nil)

      expect { report }.not_to raise_error
    end
  end
end
