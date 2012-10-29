require_relative './record_analyzer'

require 'json'

class AnalyzedActivity
  attr_accessor :uri, :type, :start_time, :duration, :distance, :distance_vector, :heart_rate, :heart_rate_vector, :calories, :notes, :gps_path, :record_analyzer, :record_distances

  def initialize uri, type, start_time, duration, distance, distance_vector, heart_rate, heart_rate_vector, calories, notes, gps_path
    @uri = uri
    @type = type
    @start_time = start_time
    @duration = duration
    @distance = distance
    @distance_vector = distance_vector
    @heart_rate = heart_rate
    @heart_rate_vector = heart_rate_vector
    @calories = calories
    @notes = notes
    @gps_path = gps_path

    @record_distances = [1000,5000,10000]

    @record_analyzer = RecordAnalyzer.new @distance_vector, @record_distances
  end

  def self.from_health_graph_activity activity
    AnalyzedActivity.new(activity.uri,
                         activity.type,
                         activity.start_time,
                         activity.duration,
                         activity.total_distance,
                         activity.distance,
                         activity.average_heart_rate,
                         activity.heart_rate,
                         activity.total_calories,
                         activity.notes,
                         activity.gps_path )
  end

  def record_distances
    [1000]
  end

  def records
    @record_analyzer.records
  end

  def persist
    {uri: @uri, type: @type, start_time: @start_time, duration: @duration, distance: @distance, distance_vector: @distance_vector.to_json, heart_rate: @heart_rate, heart_rate_vector: @heart_rate_vector, calories: @calories, notes: @notes, gps_path: @gps_path.to_json}.to_json
  end

  def self.load json_string
    loaded_activity = JSON.parse(json_string)
    new loaded_activity["uri"], loaded_activity["type"], loaded_activity["start_time"], loaded_activity["duration"], loaded_activity["distance"], JSON.parse(loaded_activity["distance_vector"]), loaded_activity["heart_rate"], loaded_activity["heart_rate_vector"], loaded_activity["calories"], loaded_activity["notes"], JSON.parse(loaded_activity["gps_path"])
  end
end
