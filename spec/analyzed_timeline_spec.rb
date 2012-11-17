require 'rspec'
require 'factory_girl'

require_relative '../lib/analyzed_timeline'
require_relative './rspec_helpers'
require_relative './factories/analyzed_activities.rb'

describe AnalyzedTimeline do
  subject(:analyzed_timeline) do
    @activities = Array(1..20).map { FactoryGirl.build :wellformed_activity }
    @activities.sort_by! { |activity| activity.start_time}
    AnalyzedTimeline.new @activities
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

  it "should return maximum cumulative distances" do
    time_periods_in_days = [1,2,7,14,30]
    cumulative_distances = analyzed_timeline.maximum_cumulative_distances time_periods_in_days
    time_periods_in_days.each do |period|
      cumulative_distances.should have_key period
    end
    cumulative_distances.each do |days, distance|
      distance[:distance].should == ((days+1)/2.0).floor*1002
    end
  end

  it "sholud return records for all activities"
end
