require 'rspec'
require 'resque_spec'
require 'factory_girl'
require 'hashie'

require_relative '../lib/analyzed_timeline'
require_relative '../lib/analyzer.rb'
require_relative './rspec_helpers'
require_relative './factories/analyzed_activities.rb'

describe AnalyzedTimeline do

  context "without loaded activities" do
    before :each do
      Redis.new.flushall
      ResqueSpec.reset!

      @activities = Array(1..20).map { FactoryGirl.build :wellformed_activity }
      @activities.sort_by! { |activity| activity.start_time}
      @analyzed_timeline = AnalyzedTimeline.new @activities.map {|a| a.uri}
    end

    it "should not have atl ready" do
      @analyzed_timeline.atl.should == :in_progress
    end

    it "should not have ctl ready" do
      @analyzed_timeline.ctl.should == :in_progress
    end

    it "should not have ctl - atl ready" do
      @analyzed_timeline.ctl_minus_atl == :in_progress
    end

    it "should not have records ready" do
      @analyzed_timeline.records.should == :in_progress
    end

    it "should not have analysis start date ready" do
      @analyzed_timeline.analysis_start_date.should == :in_progress
    end

    it "should not have maximum cumulative distances ready" do
      @analyzed_timeline.maximum_cumulative_distances(4).should == :in_progress
    end
  end

  context "with loaded activities" do
    before :each do
      Redis.new.flushall
      ResqueSpec.reset!

      @activities = Array(1..20).map { FactoryGirl.build :wellformed_activity }
      @activities.sort_by! { |activity| activity.start_time}
      @analyzed_timeline = AnalyzedTimeline.new @activities.map {|a| a.uri}
      activity_stubs = @activities.map do |activity|
        activity.to_health_graph_hash
      end

      HealthGraph::FitnessActivity.stub(:new).and_return(
                                                         activity_stubs[0],
                                                         activity_stubs[1],
                                                         activity_stubs[2],
                                                         activity_stubs[3],
                                                         activity_stubs[4],
                                                         activity_stubs[5],
                                                         activity_stubs[6],
                                                         activity_stubs[7],
                                                         activity_stubs[8],
                                                         activity_stubs[9],
                                                         activity_stubs[10],
                                                         activity_stubs[11],
                                                         activity_stubs[12],
                                                         activity_stubs[13],
                                                         activity_stubs[14],
                                                         activity_stubs[15],
                                                         activity_stubs[16],
                                                         activity_stubs[17],
                                                         activity_stubs[18],
                                                         activity_stubs[19]
                                                         )
      ResqueSpec.perform_all(:analyzer)
      @analyzed_timeline.refresh_activities!
    end

    it "should have loaded the activities" do
      @analyzed_timeline.activities.to_json.should == @activities.to_json
    end

    it "should calculate the correct start date for analysis" do
      @analyzed_timeline.analysis_start_date.should == @activities.first.start_time.to_date
    end

    it "should return atl for all days" do
      atl_hash = @analyzed_timeline.atl
      @analyzed_timeline.analysis_start_date.upto Date.today do |day|
        atl_hash.should have_key day
      end
    end

    it "should return ctl for all days" do
      ctl_hash = @analyzed_timeline.ctl
      @analyzed_timeline.analysis_start_date.upto Date.today do |day|
        ctl_hash.should have_key day
      end
    end

    it "should return ctl-atl for all days" do
      ctl_minus_atl_hash = @analyzed_timeline.ctl_minus_atl
      @analyzed_timeline.analysis_start_date.upto Date.today do |day|
        ctl_minus_atl_hash.should have_key day
      end
    end

    it "should return maximum cumulative distances" do
      time_periods_in_days = [1,2,7,14,30]
      cumulative_distances = @analyzed_timeline.maximum_cumulative_distances time_periods_in_days
      time_periods_in_days.each do |period|
        cumulative_distances.should have_key period
      end
      cumulative_distances.each do |days, distance|
        distance[:distance].should == ((days+1)/2.0).floor*1002
      end
    end
  end

  context "asynchronous analysis" do
    before :each do
      Settings.instance.record_distances = 500,1500,2000

      @activities = Array(1..3).map do |i|
        distance = 0.95**(i-1) * (i-1) * 1000
        distance_vector = []
        (i+1).times do |k|
          distance_vector << {'timestamp' => k * 300, 'distance' => k * 1000 * 0.95**(i-1)}
        end


        FactoryGirl.build :wellformed_activity, distance: distance, distance_vector: distance_vector
      end

      @complex_analyzed_timeline = AnalyzedTimeline.new @activities.map { |a| a.uri }

      activity_stubs = @activities.map do |activity|
        activity.to_health_graph_hash
      end

      HealthGraph::FitnessActivity.stub(:new).and_return(
                                                         activity_stubs[0],
                                                         activity_stubs[1],
                                                         activity_stubs[2],
                                                         )
      Redis.new.flushall
    end

    it "should return records for all activities" do

      ResqueSpec.perform_all(:analyzer)

      @complex_analyzed_timeline.records.to_json.should ==
        {
        500 =>
        [
         {
           activity: @activities[0],
           record: @activities[0].records[500]
         },
         {
           activity: @activities[1],
           record: @activities[1].records[500]
         },
         {
           activity: @activities[2],
           record: @activities[2].records[500]
         }
        ],
        1500 =>
        [
         {
           activity: @activities[1],
           record: @activities[1].records[1500]
         },
         {
           activity: @activities[2],
           record: @activities[2].records[1500]
         }
        ],
        2000 =>
        [
         {
           activity: @activities[2],
           record: @activities[2].records[2000]
         }
        ]
      }.to_json
    end

    it "should return the current progress of activity analysis" do
      @activities.each {|activity| activity.analyzed?.should be_false}
      @complex_analyzed_timeline.progress.should == {done: 0, all: @activities.size}
      ResqueSpec.perform_all(:analyzer)
      @complex_analyzed_timeline.progress.should == :all_done
    end
  end
end
