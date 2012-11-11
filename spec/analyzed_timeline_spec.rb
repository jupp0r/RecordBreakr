require 'rspec'
require 'factory_girl'

require_relative '../lib/analyzed_timeline'
require_relative './rspec_helpers'
require_relative './factories/analyzed_activities.rb'

describe AnalyzedTimeline do
  subject(:analyzed_timeline) do
    AnalyzedTimeline.new @activities
  end

  before :each do
    @activities = [1..20].map { FactoryGirl.build :complex_activity }
  end

  it "should calculate the correct start date for analysis" do
    analyzed_timeline.analysis_start_date.should == @activities.first.start_time.to_date
  end

  it "should return atl for all days" do
    atl_hash = analyzed_timeline.atl
    analyzed_timeline.analysis_start_date.upto Date.today do |day|
      atl_hash.should have_key day
    end
  end

  it "should return ctl for all days" do
    ctl_hash = analyzed_timeline.ctl
    analyzed_timeline.analysis_start_date.upto Date.today do |day|
      ctl_hash.should have_key day
    end
  end

  it "should return ctl-atl for all days" do
    ctl_minus_atl_hash = analyzed_timeline.ctl_minus_atl
    analyzed_timeline.analysis_start_date.upto Date.today do |day|
      ctl_minus_atl_hash.should have_key day
    end
  end

  it "should return maximum cumulative distances"
  it "sholud return records for all activities"
end
