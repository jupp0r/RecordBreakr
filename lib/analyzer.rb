require "resque-status"
require "health_graph"

class Analyzer
  include Resque::Plugins::Status

  def perform
    HealthGraph.configure do |config|
      config.client_id = ENV["CLIENT_ID"]
      config.client_secret = ENV["CLIENT_SECRET"]
      config.authorization_redirect_url = ENV["REDIRECT_URL"]
    end

    job_id = @uuid
    redis = Redis.new
    @token = options["token"]
    @distances = options["distances"]


    health_graph_user = HealthGraph::User.new @token

    @user = health_graph_user.userID
    @activity_uri = options["activity_uri"]

    activity = HealthGraph::FitnessActivity.new @token, "uri" => @activity_uri
    @distance_vector = activity.distance

    redis.setnx  "Activities:#{@activity_uri}:url", activity.activity

    @distances.each do |distance|
      record = calculate_fastest_distance distance, @distance_vector
      redis.hmset "Activities:#{@activity_uri}:record:#{distance}", "time", record[:time], "start", record[:start], "stop", record[:stop] unless record.nil?
    end

    redis.multi do
      redis.sadd "Users:#{@user}:analyzed_activities", @activity_uri
      redis.srem "Users:#{@user}:analyzing_activities", @activity_uri
      redis.srem "Users:#{@user}:running_jobs", job_id
    end
  end

  def calculate_fastest_distance target_distance, distance_vector
    return nil if distance_vector.nil? or distance_vector.last.nil? or target_distance > distance_vector.last["distance"]
    fastest_race_time = Float::INFINITY
    fastest_race_start = 0.0
    fastest_race_stop = 0.0
    distance_vector.each do |start_point|
      last_end_point = start_point
      distance_vector.each do |end_point|
        if start_point["timestamp"] < end_point["timestamp"]
          distance_start_to_end = end_point["distance"] - start_point["distance"]
          if target_distance <= distance_start_to_end
            # linear interpolation of intermediate time
            error_distance = distance_start_to_end - target_distance
            diff_time = end_point["timestamp"] - last_end_point["timestamp"]
            diff_distance = end_point["distance"] - last_end_point["distance"]
            stop_time = last_end_point["timestamp"] + diff_time*(diff_distance/error_distance)
            current_race_time =  stop_time - start_point["timestamp"]
            fastest_race_time = current_race_time if current_race_time < fastest_race_time
            fastest_race_start = start_point["timestamp"]
            fastest_race_stop = stop_time
            break
          end
        end
        last_end_point = end_point
      end
    end
    {:time => fastest_race_time, :start => fastest_race_start, :stop => fastest_race_stop}
  end
end
