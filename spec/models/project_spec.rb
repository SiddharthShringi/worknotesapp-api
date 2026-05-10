require "rails_helper"

RSpec.describe Project, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      project = build(:project)
      expect(project).to be_valid
    end

    it "is invalid without a name" do
      project = build(:project, name: nil)
      expect(project).not_to be_valid
    end

    it "is invalid without a color" do
      project = build(:project, color: nil)
      expect(project).not_to be_valid
    end

    it "is invalid without a user" do
      project = build(:project, user: nil)
      expect(project).not_to be_valid
    end

    it "is invalid if project name is not unique for a user" do
      user = create(:user)
      create(:project, name: "Project 1", user: user)
      project = build(:project, name: "Project 1", user: user)

      expect(project).not_to be_valid
    end

    it "does not allow case-insensitive duplicate names for same user" do
      user = create(:user)
      create(:project, name: "CS50", user: user)
      project = build(:project, name: "cs50", user: user)

      expect(project).not_to be_valid
    end
  end

  describe "scopes" do
    it "returns only active projects" do
      active_project = create(:project)
      archived_project = create(:project, archived: true)

      expect(described_class.active).to include(active_project)
      expect(described_class.active).not_to include(archived_project)
    end

    it "returns only archived projects" do
      active_project = create(:project)
      archived_project = create(:project, archived: true)

      expect(described_class.archived).to include(archived_project)
      expect(described_class.archived).not_to include(active_project)
    end
  end

  describe "color enum" do
    it "raise Argument Error for invalid color" do
      project = build(:project)
      expect { project.color = "black" }.to raise_error(ArgumentError)
    end
  end

  describe ".filter_by" do
    let!(:active_project) do
      create(:project, archived: false)
    end

    let!(:archived_project) do
      create(:project, archived: true)
    end

    context "when status is active" do
      it "returns active projects" do
        result = described_class.filter_by(status: "active")

        expect(result).to contain_exactly(active_project)
      end
    end

    context "when status is archived" do
      it "returns archived projects" do
        result = described_class.filter_by(status: "archived")

        expect(result).to contain_exactly(archived_project)
      end
    end

    context "when status is unknown" do
      it "returns all projects" do
        result = described_class.filter_by(status: "unknown")

        expect(result)
          .to contain_exactly(active_project, archived_project)
      end
    end

    context "when status is missing" do
      it "returns all projects" do
        result = described_class.filter_by({})

        expect(result)
          .to contain_exactly(active_project, archived_project)
      end
    end
  end
end
