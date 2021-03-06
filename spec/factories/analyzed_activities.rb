require 'factory_girl'
require 'mock_redis'

FactoryGirl.define do
  sequence :date do |n|
    (Time.new(2012).to_date + 2*n).to_datetime
  end

  sequence :uri do |n|
    "activities/#{n}"
  end

  factory :empty_activity, class: AnalyzedActivity do
    uri { generate :uri }
    type "Running"
    start_time Time.new(2012).to_datetime
    duration 0
    distance 0
    distance_vector []
    heart_rate 0
    heart_rate_vector []
    calories 0
    notes ""
    gps_path []
    initialize_with { new(uri,type,start_time, duration, distance, distance_vector, heart_rate, heart_rate_vector, calories, notes, gps_path) }
    redis MockRedis.new
  end

  factory :exact_distance_activity, parent: :empty_activity do
    distance_vector [{'timestamp' => 0.0, 'distance' => 0.0},
                     {'timestamp' => 5.0, 'distance' => 1002}]
  end

  factory :distance_two_point_activity, parent: :empty_activity do
    distance_vector [
                     {'timestamp' => 0.0, 'distance' => 0.0},
                     {'timestamp' => 5.0, 'distance' => 1.0},
                     {'timestamp' => 10.0, 'distance' => 1001.0},
                     {'timestamp' => 15.0, 'distance' => 1002.0}
                    ]
  end

  factory :complex_activity, parent: :distance_two_point_activity do
    start_time { generate :date }
    heart_rate_vector [{'timestamp' => 0.0, 'heart_rate' => 150},
                       {'timestamp' => 600.0, 'heart_rate' => 155},
                       {'timestamp' => 1200.0, 'heart_rate' => 145},
                       {'timestamp' => 1800.0, 'heart_rate' => 140}]
  end

  factory :wellformed_activity, parent: :complex_activity do
    distance 1002.0
  end
end
