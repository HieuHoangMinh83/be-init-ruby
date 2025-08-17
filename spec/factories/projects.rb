FactoryBot.define do
  factory :project do
    name { Faker::App.name }
    description { Faker::Lorem.sentence }
    association :user

    factory :project_with_tasks do
      transient do
        tasks_count { 5 }
      end

      after(:create) do |project, evaluator|
        create_list(:task, evaluator.tasks_count, project: project)
      end
    end
  end
end
