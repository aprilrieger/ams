require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_date, class: PBCore::Instantiation::Date, parent: :pbcore_element do
    skip_create

    type { Faker::Types.rb_string }
    value { Faker::Date.backward(14) }

    trait :digitized do
      type { "digitized" }
    end

    initialize_with { new(attributes) }
  end
end