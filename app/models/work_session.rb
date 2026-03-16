class WorkSession < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :intent, presence: true
  validates :started_at, presence: true

  validate :ended_after_started

  private

  def ended_after_started
    return if ended_at.blank?

    if ended_at < started_at
      errors.add(:ended_at, "must be after started_at")
    end
  end
end
