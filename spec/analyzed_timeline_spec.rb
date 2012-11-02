require 'rspec'
require 'factory_girl'

require_relative '../lib/analyzed_timeline'
require_relative './rspec_helpers'
require_relative './factories/analyzed_activities.rb'

describe AnalyzedTimeline do
  it "should return atl for all days" do
    activities = [1..20].map { build :complex_activity }
    analyzed_timeline = AnalyzedTimeline.new activities
    atl_hash = analyzed_timeline.atl
    atl_hash.should have_key activities.first.start_time.to_date
    atl_hash.should have_key Date.today
  end
  it "should return ctl for all days"
  it "should return ctl-atl for all days"
  it "should return maximum cumulative distances"
  it "sholud return records for all activities"
end
