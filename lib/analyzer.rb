require "health_graph"
require_relative "./analyzed_activity"

class Analyzer
  @queue = :analyzer

  def self.perform activity_uri, settings
    HealthGraph.configure do |config|
      config.client_id = ENV["CLIENT_ID"]
      config.client_secret = ENV["CLIENT_SECRET"]
      config.authorization_redirect_url = ENV["REDIRECT_URL"]
    end

    redis = Redis.new

    load_settings settings

    @token = Settings.instance.token

    @activity_uri = activity_uri

    @fitness_activity = HealthGraph::FitnessActivity.new @token, "uri" => @activity_uri
    analyzed_activity = AnalyzedActivity.from_health_graph_activity @fitness_activity

    set_redis_activity_link

    analyzed_activity.save

    update_redis_status
  end

  def self.update_redis_status
    redis = Redis.new
    redis.multi do
      redis.sadd "analyzed_activities", @activity_uri
      redis.srem "analyzing_activities", @activity_uri
    end
  end

  def self.set_redis_activity_link
    redis = Redis.new
    redis.setnx  "Activities:#{@activity_uri}:url", @fitness_activity.activity
  end

  def self.load_settings settings_from_resque
    Settings.load_from_hash settings_from_resque
  end
end
