FactoryBot.define do
  factory :work_session do
    association :user
    association :project

    intent { "Implement work session feature" }
    notes { "Worked on migrations and validations" }

    started_at { Time.current }
    ended_at { nil }

    trait :completed do
      started_at { 2.hours.ago }
      ended_at { 1.hour.ago }
    end
  end
end
