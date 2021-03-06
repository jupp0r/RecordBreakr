#!/usr/bin/env ruby
# vim: et ts=2 sw=2

require "haml"
require "sass"
require "set"
require "date"
require "health_graph"
require "sinatra"
require "redis"
require "json"
require "./lib/analyzer"
require "coffee_script"

redis = Redis.new

HealthGraph.configure do |config|
  config.client_id = ENV["CLIENT_ID"]
  config.client_secret = ENV["CLIENT_SECRET"]
  config.authorization_redirect_url = ENV["REDIRECT_URL"]
end

ENV['EXECJS_RUNTIME'] = 'Node'

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
    "%g km" %  ("%.2f" % (distance/1000.0))
  end

  def calculate_average_pace total_distance, duration
    duration*1000/total_distance
  end

  def format_item item
    date = item.start_time.to_date
    duration = format_duration item.duration
    distance = format_distance item.total_distance
    pace = format_duration(item.duration/(item.total_distance/1000))
    {:date => date, :duration => duration, :distance => distance, :pace => pace}
  end

  def retrieve_records token, user, activities
    redis = Redis.new
    records = Hash.new

    distances = Settings.instance.record_distances

    distances.each do |distance|
      records[distance] = Hash.new
    end

    @fitness_items.each do |fitness_item|
      if redis.sismember "analyzed_activities", fitness_item.uri
        activity = AnalyzedActivity.load fitness_item.uri, redis
        distances.each do |distance|
          unless activity.records.nil? or activity.records[distance].nil?
            records[distance][fitness_item.uri] = activity.records[distance]
            @urls[fitness_item.uri] = redis.get "Activities:#{fitness_item.uri}:url"
          end
        end
      elsif redis.sismember "analyzing_activities", fitness_item.uri
        @processing.push fitness_item.uri
      else
        redis.sadd "analyzing_activities", fitness_item.uri
        job_id = Analyzer.create(:token => token, :activity_uri => fitness_item.uri, :settings => Settings.instance.to_hash)
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

  def calculate_day_statistics fitness_items, day_intervals
    day_distances = Hash.new

    start_dates = Hash.new
    end_dates = Hash.new
    items = Hash.new

    day_intervals.each do |interval|
      day_distances[interval] = 0.0
    end

    fitness_items.each do |fitness_item_early|
      start_time_early = fitness_item_early.start_time.to_date

      cumulated_distance = Hash.new
      item_list = Hash.new

      day_intervals.each do |interval|
        cumulated_distance[interval] = fitness_item_early.total_distance
        item_list[interval] = [fitness_item_early]
      end

      fitness_items.each do |fitness_item_late|
        start_time_late = fitness_item_late.start_time.to_date
        if start_time_late > start_time_early
          day_intervals.each do |interval|
            if start_time_late - start_time_early < interval
              cumulated_distance[interval] += fitness_item_late.total_distance
              item_list[interval].push fitness_item_late
            end
          end
        end
      end

      day_intervals.each do |interval|
        if cumulated_distance[interval] > day_distances[interval]
          day_distances[interval] = cumulated_distance[interval]
          start_dates[interval] = start_time_early
          end_dates[interval] = start_time_early + interval
          items[interval] = item_list[interval]
        end
      end
    end

    items.each_value do |item_list|
      item_list.sort_by! do |item|
        item.start_time.to_time
      end
    end

    {:day_distances => day_distances, :start_dates => start_dates, :end_dates => end_dates, :items => items}

  end

  def load_settings
    Settings.instance.gender = :male
    Settings.instance.resting_heart_rate = 55
    Settings.instance.maximum_heart_rate = 180
    Settings.instance.record_distances = [1000, 5000, 10000, 21097, 30000, 42195]
  end

end

get "/" do
  @number_of_activities = 30

  @day_intervals = [2,7,14,30,365]

  load_settings

  token = request.cookies["token"]
  redirect "/auth" unless token

  settings.token = token

  user = HealthGraph::User.new token

  @uid = user.userID

  #store user in user list

  redis.sadd "Users:all", @uid

  feed = user.fitness_activities

  @fitness_items = []

  @processing = []

  while feed
    @fitness_items += feed.items.nil? ? [] : feed.items
    feed = feed.next_page
  end

  @fitness_items.select! do |activity|
    activity.type == "Running"
  end

  @day_records = calculate_day_statistics @fitness_items, @day_intervals

  @urls = Hash.new

  @records = retrieve_records token, user, @fitness_items


  @topten = []
  @number_of_activities.times {@topten.push Hash.new}
  Settings.instance.record_distances.each do |distance|
    (0..@number_of_activities-1).each do |i|
      if @records[distance].size > i
        topten_item = @records[distance].keys[i]
        @topten[i][distance] = {:activity => topten_item, :record => @records[distance][topten_item]}
      end
    end
  end

  @tooltip_activities = @fitness_items.select do |activity|
    @urls.keys.include? activity.uri
  end

  haml :index, :format => :html5
end

get "/progress" do
  content_type :json
  token = request.cookies["token"]
  user = HealthGraph::User.new token

  @uid = user.userID

  redis = Redis.new

  incomplete_items = redis.smembers("analyzing_activities").size
  complete_items = redis.smembers("analyzed_activities").size

  {:complete => complete_items, :incomplete => incomplete_items}.to_json
end

get "/refresh" do
  token = request.cookies["token"]
  user = HealthGraph::User.new token
  redis = Redis.new
  redis.del "analyzed_activities"
  redirect "/"
end

get "/auth" do
  redirect HealthGraph.authorize_url
end

get "/callback" do
  token = HealthGraph.access_token params[:code]
  response.set_cookie "token", token
  redirect "/"
end

get "/ui.css" do
  content_type "text/css"
  scss :ui
end

get '/ui.js' do
  content_type "text/javascript"
  coffee :ui
end

get '/navigation.jpg' do
  File.read(File.join("views","navigation.jpg"))
end
