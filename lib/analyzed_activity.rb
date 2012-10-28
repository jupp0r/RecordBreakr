require_relative './record_analyzer'

class AnalyzedActivity
  attr_accessor :uri, :type, :start_time, :duration, :distance, :distance_vector, :heart_rate, :heart_rate_vector, :calories, :notes, :gps_path, :record_analyzer

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

end
