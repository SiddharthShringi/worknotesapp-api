class WorkSession < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :intent, presence: true
  validates :started_at, presence: true

  validate :ended_after_started
  validate :only_one_active_session, on: :create

  def duration
    return nil unless ended_at.present?

    ended_at - started_at
  end

  private

  def ended_after_started
    return if ended_at.blank?

    if ended_at < started_at
      errors.add(:ended_at, "must be after started_at")
    end
  end

  def only_one_active_session
    return if ended_at.present?

    if user.work_sessions.where(ended_at: nil).exists?
      errors.add(:base, "You already have an active session")
    end
  end
end
