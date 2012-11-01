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

    load_settings options["settings"]

    health_graph_user = HealthGraph::User.new @token

    @user = health_graph_user.userID
    @activity_uri = options["activity_uri"]

    fitness_activity = HealthGraph::FitnessActivity.new @token, "uri" => @activity_uri
    analyzed_activity = AnalyzedActivity.from_health_graph_activity fitness_activity

    redis.setnx  "Activities:#{@activity_uri}:url", fitness_activity.activity

    analyzed_activity.save

    redis.multi do
      redis.sadd "Users:#{@user}:analyzed_activities", @activity_uri
      redis.srem "Users:#{@user}:analyzing_activities", @activity_uri
      redis.srem "Users:#{@user}:running_jobs", job_id
    end
  end

  def load_settings settings_from_resque
    Settings.load_from_hash settings_from_resque
  end
end
