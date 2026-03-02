class Project < ApplicationRecord
  belongs_to :user

  enum :color, {
    blue: "blue",
    green: "green",
    amber: "amber",
    red: "red",
    violet: "violet",
    cyan: "cyan",
    pink: "pink",
    lime: "lime",
    orange: "orange",
    indigo: "indigo",
    teal: "teal",
    rose: "rose"
  }

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :color, presence: true

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
end
