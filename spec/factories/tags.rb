FactoryBot.define do
  factory :tag do
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
  end
end
