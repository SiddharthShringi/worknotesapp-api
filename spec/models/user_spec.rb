require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is invalid without a first_name" do
      user = build(:user, first_name: nil)
      expect(user).not_to be_valid
    end

    it "is invalid without a last_name" do
      user = build(:user, last_name: nil)
      expect(user).not_to be_valid
    end
  end
end
