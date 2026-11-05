class Export < ApplicationRecord
  belongs_to :user
  has_one_attached :pdf

  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :status, presence: true

  scope :active, -> { where(status: [ :pending, :processing ]) }
  scope :expired, -> { where("created_at < ?", 24.hour.ago) }
end
