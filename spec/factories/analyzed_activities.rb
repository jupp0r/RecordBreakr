require 'factory_girl'

FactoryGirl.define do
  initialize_with { new(uri,type,start_time, duration, distance, distance_vector, heart_rate, heart_rate_vector, calories, notes, gps_path) }

  factory :empty_activity, class: AnalyzedActivity do
    uri ""
    type ""
    start_time Time.at(0)
    duration 0
    distance 0
    distance_vector []
    heart_rate 0
    heart_rate_vector []
    calories 0
    notes ""
    gps_path []
  end

  factory :exact_distance_activity, parent: :empty_activity do
    distance_vector [{'timestamp' => 0.0, 'distance' => 0.0},
                     {'timestamp' => 5.0, 'distance' => 1000}]
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
    heart_rate_vector [{'timestamp' => 0.0, 'heart_rate' => 150},
                       {'timestamp' => 5.0, 'heart_rate' => 155},
                       {'timestamp' => 10.0, 'heart_rate' => 145},
                       {'timestamp' => 15.0, 'heart_rate' => 140}]
  end
end
