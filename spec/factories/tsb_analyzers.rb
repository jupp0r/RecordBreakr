require 'factory_girl'
require_relative './analyzed_activities'

FactoryGirl.define do
  factory :empty_tsb_analyzer, class: TsbAnalyzer do
    activities []
    initialize_with {new(activities)}
  end

  factory :one_activity_tsb_analyzer, parent: :empty_tsb_analyzer do
    activities {[build(:complex_activity)]}
  end

  factory :two_activity_tsb_analyzer, parent: :empty_tsb_analyzer do
    activities do
      activity_one = build :complex_activity, start_time: Time.at(0).to_datetime
      activity_two = build :complex_activity, start_time: (Time.at(0).to_date + 1).to_datetime
      [activity_one, activity_two]
    end
  end
end
