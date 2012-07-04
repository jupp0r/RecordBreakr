#!/usr/bin/env ruby
# vim: et ts=2 sw=2

require "set"
require "date"
require "health_graph"
require "sinatra"

HealthGraph.configure do |config|
  config.client_id = ENV["CLIENT_ID"]
  config.client_secret = ENV["CLIENT_SECRET"]
  config.authorization_redirect_url = ENV["REDIRECT_URL"]
end

get "/" do
  token = request.cookies["token"]
  redirect "/auth" unless token

  user = HealthGraph::User.new token

  feed = user.fitness_activities

  @fitness_items = []

  while feed
    @fitness_items += feed.items
    feed = feed.next_page
  end

  "bla"
end

get "/auth" do
  redirect HealthGraph.authorize_url
end

get "/callback" do
  token = HealthGraph.access_token params[:code]
  response.set_cookie "token", token
  redirect "/"
end
