FactoryBot.define do
  factory :user_setting do
    theme { "light" }
    notifications_enabled { true }
    language { "en" }
    association :user
  end
end
