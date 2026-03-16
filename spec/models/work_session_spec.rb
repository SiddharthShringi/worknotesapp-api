require "rails_helper"

RSpec.describe WorkSession, type: :model do
  describe "associations" do
    it "belongs to a user" do
      user = create(:user)
      project = create(:project, user: user)

      work_session = create(:work_session, user: user, project: project)

      expect(work_session.user).to eq(user)
    end

    it "belongs to a project" do
      user = create(:user)
      project = create(:project, user: user)

      work_session = create(:work_session, user: user, project: project)

      expect(work_session.project).to eq(project)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      work_session = build(:work_session)
      expect(work_session).to be_valid
    end

    it "is invalid without intent" do
      work_session = build(:work_session, intent: nil)

      expect(work_session).not_to be_valid
      expect(work_session.errors[:intent]).to include("can't be blank")
    end

    it "is invalid without started_at" do
      work_session = build(:work_session, started_at: nil)

      expect(work_session).not_to be_valid
      expect(work_session.errors[:started_at]).to include("can't be blank")
    end
  end

  describe "time validation" do
    let(:started_at) { Time.current }

    it "allows ended_at to be nil for active sessions" do
      work_session = build(:work_session, ended_at: nil)

      expect(work_session).to be_valid
    end

    it "is valid when ended_at is after started_at" do
      work_session = build(:work_session, started_at: started_at, ended_at: started_at + 1.hour)

      expect(work_session).to be_valid
    end

    it "is invalid when ended_at is before started_at" do
      work_session = build(:work_session, started_at: started_at, ended_at: started_at - 1.hour)

      expect(work_session).not_to be_valid
      expect(work_session.errors[:ended_at]).to include("must be after started_at")
    end

    it "is invalid when already one active session" do
      work_session1 = create(:work_session, ended_at: nil)
      work_session2 = build(:work_session, ended_at: nil)


      expect(work_session2).not_to be_valid
      expect(work_session.errors[:ended_at]).to include("must be after started_at")
    end
  end
end
