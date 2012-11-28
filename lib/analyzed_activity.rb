require_relative './record_analyzer'
require_relative './trimp_analyzer'
require_relative './settings'

require 'json'
require 'redis'
require 'date'

class AnalyzedActivity
  attr_accessor :uri, :type, :start_time, :duration, :distance, :distance_vector, :heart_rate, :heart_rate_vector, :calories, :notes, :gps_path, :record_analyzer, :trimp_analyzer, :redis

  attr_writer :records, :trimp

  def initialize uri, type, start_time, duration, distance, distance_vector, heart_rate, heart_rate_vector, calories, notes, gps_path, settings = Settings.instance, redis = Redis.new
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

    @settings = settings

    @record_analyzer = RecordAnalyzer.new @distance_vector, @settings.record_distances
    @trimp_analyzer = TrimpAnalyzer.new @heart_rate_vector, @settings.resting_heart_rate, @settings.maximum_heart_rate, @settings.gender

    @redis = redis
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

  def records
    if @records
      @records
    else
      @records = @record_analyzer.records
    end
  end

  def trimp
    if @trimp
      @trimp
    else
      @trimp = @trimp_analyzer.trimp
    end
  end

  def cached?
    not (@records.nil? or @trimp.nil?)
  end

  alias_method :analyzed?, :cached?

  def flush
    @records = nil
    @trimp = nil
    @redis.del redis_key
  end

  def to_health_graph_hash
    Hashie::Mash.new uri: @uri, type: @type, start_time: @start_time, duration: @duration, total_distance: @distance, distance: @distance_vector, average_heart_rate: @heart_rate, heart_rate: @heart_rate_vector, total_calories: @calories, notes: @notes, gps_path: @gps_path
  end

  def to_json options = {}
    {uri: @uri, type: @type, start_time: @start_time.to_s, duration: @duration, distance: @distance, distance_vector: @distance_vector, heart_rate: @heart_rate, heart_rate_vector: @heart_rate_vector, calories: @calories, notes: @notes, gps_path: @gps_path, records: records, trimp: trimp}.to_json
  end

  def to_json_without_analysis options = {}
    {uri: @uri, type: @type, start_time: @start_time.to_s, duration: @duration, distance: @distance, distance_vector: @distance_vector, heart_rate: @heart_rate, heart_rate_vector: @heart_rate_vector, calories: @calories, notes: @notes, gps_path: @gps_path, records: nil, trimp: nil}.to_json
  end

  def self.load uri, redis = Redis.new
    json_activity = redis.get "Activities:#{uri}"
    return nil if json_activity.nil?
    self.from_json json_activity
  end

  def save
    @redis.set redis_key, to_json
  end

  def self.from_json json_string
    loaded_activity = JSON.parse(json_string)
    new_activity = self.new loaded_activity["uri"], loaded_activity["type"], DateTime.parse(loaded_activity["start_time"]), loaded_activity["duration"], loaded_activity["distance"], loaded_activity["distance_vector"], loaded_activity["heart_rate"], loaded_activity["heart_rate_vector"], loaded_activity["calories"], loaded_activity["notes"], loaded_activity["gps_path"]
    new_activity.records = coerce_hash loaded_activity["records"], :to_i, [:to_sym, nil]
    new_activity.trimp = loaded_activity["trimp"].to_f
    new_activity
  end

  def self.analyzed? uri, redis = Redis.new
    redis.sismember "analyzed_activities", uri
  end

  def self.analyzing? uri, redis = Redis.new
    redis.sismember "analyzing_activities", uri
  end

  private

  def self.coerce_hash hash, key_fun, args
    return nil if hash.nil?
    hash.each_with_object({}) do |(k,v),h|
      h[k.send key_fun] = if not args.nil? and args.length > 1
                            self.coerce_hash v, args[0], args[1..-1]
                          else
                            if args.first.nil?
                              v
                            else
                              v.send args.first
                            end
                          end
    end
  end

  def redis_key
    "Activities:#{@uri}"
  end

end
