#!/usr/bin/env ruby
# vim: et ts=2 sw=2

require "haml"
require "set"
require "date"
require "health_graph"
require "sinatra"
require "redis"

require "./lib/analyzer"

redis = Redis.new

HealthGraph.configure do |config|
  config.client_id = ENV["CLIENT_ID"]
  config.client_secret = ENV["CLIENT_SECRET"]
  config.authorization_redirect_url = ENV["REDIRECT_URL"]
end

helpers do
  def parse_duration duration_in_s
    duration_in_s = (duration_in_s+0.5).to_i
    hours = duration_in_s/3600
    minutes = (duration_in_s % 3600) / 60
    seconds = duration_in_s % 60
    {:hours => hours, :minutes => minutes, :seconds => seconds}
  end

  def format_duration duration
    converted = parse_duration duration
    output_str = "%02d" % converted[:seconds]
    output_str = "%02d:" % converted[:minutes] + output_str unless converted[:minutes] == 0 and converted[:hours] == 0
    output_str =  "#{converted[:hours]}:" + output_str unless converted[:hours] == 0
    output_str
  end

  def format_distance distance
    "%#.2f km" % (distance/1000)
  end

  def calculate_average_pace total_distance, duration
    duration*1000/total_distance
  end

  def retrieve_records token, user, activities, distances
    redis = Redis.new
    records = Hash.new

    distances.each do |distance|
      records[distance] = Hash.new
    end

    @fitness_items.each do |fitness_item|
      if redis.sismember "Users:#{user.userID}:analyzed_activities", fitness_item.uri
        distances.each do |distance|
          records[distance][fitness_item.uri] = Hash[redis.hgetall("Activities:#{fitness_item.uri}:record:#{distance}").map{|(k,v)| [k.to_sym,v.to_f]}]
          @urls[fitness_item.uri] = redis.get "Activities:#{fitness_item.uri}:url"
        end
      elsif redis.sismember "Users:#{user.userID}:analyzing_activities", fitness_item.uri
        # TODO: somehow inform someone that activity is still being
        # analyzed
      else
        job_id = Analyzer.create(:distances => distances, :token => token, :activity_uri => fitness_item.uri)
        redis.sadd "Users:#{user.userID}:running_jobs", job_id
      end
    end

    #sort distances
    records.each_key do |distance|
      records[distance] = records[distance].sort_by do |activity_uri, result|
        unless result.nil? or result[:time].nil? or result.empty?
          result[:time]
        else
          Float::INFINITY
        end
      end
      records[distance] = Hash[records[distance]]
    end
    records
  end
end

get "/" do
  @distances = [1000, 5000, 10000, 21097, 42195]
  token = request.cookies["token"]
  redirect "/auth" unless token

  user = HealthGraph::User.new token

  @uid = user.userID

  #store user in user list

  redis.sadd "Users:all", @uid

  feed = user.fitness_activities

  @fitness_items = []

  while feed
    @fitness_items += feed.items
    feed = feed.next_page
  end

  @urls = Hash.new

  @records = retrieve_records token, user, @fitness_items, @distances

  # @records = Hash.new
  # @distances.each do |distance|
  #   @records[distance] = Hash.new
  #   @activities.each do |activity|
  #     record_hash = redis.hget "Activities:#{activity.uri}:record:#{distance}"
  #     unless record_hash.nil?
  #       @records[distance][activity] = record_hash[distance]
  #     else
  #       # TODO(jupp0r): trigger job start here
  #       @records[distance][activity] = nil
  #     end
  #   end
  # end

  @topten = []
  10.times {@topten.push Hash.new}
  @distances.each do |distance|
    (0..9).each do |i|
      if @records[distance].size > i
        topten_item = @records[distance].keys[i]
        @topten[i][distance] = {:activity => topten_item, :record => @records[distance][topten_item]}
      end
    end
  end

  haml :index, :format => :html5
end

get "/auth" do
  redirect HealthGraph.authorize_url
end

get "/callback" do
  token = HealthGraph.access_token params[:code]
  response.set_cookie "token", token
  redirect "/"
end
