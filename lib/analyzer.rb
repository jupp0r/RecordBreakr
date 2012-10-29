require "resque-status"
require "health_graph"
require_relative "./analyzed_activity"

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

    fitness_activity = HealthGraph::FitnessActivity.new @token, "uri" => @activity_uri
    analyzed_activity = AnalyzedActivity.from_health_graph_activity fitness_activity
    analyzed_activity.record_distances = @distances

    redis.setnx  "Activities:#{@activity_uri}:url", fitness_activity.activity

    records = analyzed_activity.records

    @distances.each do |distance|
      record = records[distance]
      redis.hmset "Activities:#{@activity_uri}:record:#{distance}", "time", record[:time], "start", record[:start], "stop", record[:stop] unless record.nil?
    end

    redis.multi do
      redis.sadd "Users:#{@user}:analyzed_activities", @activity_uri
      redis.srem "Users:#{@user}:analyzing_activities", @activity_uri
      redis.srem "Users:#{@user}:running_jobs", job_id
    end
  end
end
