FactoryBot.define do
  factory :export do
    association :user
    status { :pending }
    filters { { date: Date.current.iso8601 } }
  end
end
