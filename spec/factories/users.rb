factory :user do
  name { "Default" }
  email { Faker::Internet.email }
  password { "password123" }

  trait :admin do
    role { "admin" }
  end
  trait :guest do
    role { "guest" }
  end
  trait :active do
    active { true }
  end
  trait :confirm do
    role { "user" }
    active { true }
    confirmed { true }
  end
end
