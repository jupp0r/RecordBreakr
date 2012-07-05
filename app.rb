#!/usr/bin/env ruby
# vim: et ts=2 sw=2

require "haml"
require "set"
require "date"
require "health_graph"
require "sinatra"

HealthGraph.configure do |config|
  config.client_id = ENV["CLIENT_ID"]
  config.client_secret = ENV["CLIENT_SECRET"]
  config.authorization_redirect_url = ENV["REDIRECT_URL"]
end

helpers do
  def calculate_fastest_distance target_distance, fitness_activity
    return nil unless target_distance < fitness_activity.distance.last.distance
    fastest_race_time = Float::INFINITY
    fastest_race_start = 0.0
    fastest_race_stop = 0.0
    fitness_activity.distance.each do |start_point|
      last_end_point = start_point
      fitness_activity.distance.each do |end_point|
        if start_point.timestamp < end_point.timestamp
          distance_start_to_end = end_point.distance - start_point.distance
          if target_distance <= distance_start_to_end
            # linear interpolation of intermediate time
            error_distance = distance_start_to_end - target_distance
            diff_time = end_point.timestamp - last_end_point.timestamp
            diff_distance = end_point.distance - last_end_point.distance
            stop_time = last_end_point.timestamp + diff_time*(diff_distance/error_distance)
            current_race_time =  stop_time - start_point.timestamp
            fastest_race_time = current_race_time if current_race_time < fastest_race_time
            fastest_race_start = start_point.timestamp
            fastest_race_stop = stop_time
            break
          end
        end
        last_end_point = end_point
      end
    end
    {:time => fastest_race_time, :start => fastest_race_start, :stop => fastest_race_stop}
  end

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
      @records[distance][activity] = calculate_fastest_distance distance, activity
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
