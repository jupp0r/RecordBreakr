#!/usr/bin/env ruby
# vim: et ts=2 sw=2

require "haml"
require "set"
require "date"
require "health_graph"
require "sinatra"
require "redis"

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

  @activities = []

  @fitness_items.each do |fitness_item|
    @activities.push fitness_item.item
  end

  @records = Hash.new
  @distances.each do |distance|
    @records[distance] = Hash.new
    @activities.each do |activity|
      record_hash = redis.hget "Activities:#{activity.uri}:record:#{distance}"
      unless record_hash.nil?
        @records[distance][activity] = record_hash[distance]
      else
        # TODO(jupp0r): trigger job start here
        @records[distance][activity] = nil
      end
    end
    @records[distance] = @records[distance].sort_by do |activity, result|
      unless result.nil?
        result[:time]
      else
        Float::INFINITY
      end
    end
    @records[distance] = Hash[@records[distance]]
  end

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
