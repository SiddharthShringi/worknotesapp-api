FactoryBot.define do
  factory :project do
    association :user

    sequence(:name) { |n| "Project #{n}" }

    color { Project.colors.keys.sample }

    archived { false }

    trait :archived do
      archived { true }
    end
  end
end
