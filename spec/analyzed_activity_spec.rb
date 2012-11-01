require_relative '../lib/analyzed_activity'
require_relative './factories/analyzed_activities'
require_relative './rspec_helpers'

require 'mock_redis'

describe AnalyzedActivity do

  describe "#records" do
    subject(:activity) { build :empty_activity, record_analyzer: mock("record_analyzer") }
    it "should use the RecordAnalyzer to analize records"  do
      activity.record_analyzer.should_receive :records
      activity.records
    end
  end

  describe "#to_json" do
    subject(:activity) { FactoryGirl.build :empty_activity }
    it "should serialize to json" do
      activity.to_json.should === {uri:activity.uri, type:activity.type, start_time:activity.start_time, duration:0, distance:0, distance_vector:[], heart_rate:0, heart_rate_vector:[], calories:0, notes:"", gps_path:[], records:nil, trimp: 0.0}.to_json
    end
  end

  describe "#from_json" do
    it "should load empty activity from json" do
      created_activity = FactoryGirl.build :empty_activity
      serialized_activity = {uri:created_activity.uri, type:created_activity.type, start_time:created_activity.start_time, duration:0, distance:0, distance_vector:[], heart_rate:0, heart_rate_vector:[], calories:0, notes:"", gps_path:[], records: created_activity.records, trimp: created_activity.trimp}.to_json
      created_activity.to_json.should eq serialized_activity
      loaded_activity = AnalyzedActivity.from_json serialized_activity
      loaded_activity.to_json.should eq created_activity.to_json
    end
    it "should load filled activity" do
      complex_activity = FactoryGirl.build :complex_activity
      serialized_activity = {uri:complex_activity.uri, type: complex_activity.type ,start_time:complex_activity.start_time, duration:0, distance:0, distance_vector:complex_activity.distance_vector,heart_rate:0,heart_rate_vector:complex_activity.heart_rate_vector,calories:0,notes:"",gps_path:[], records: complex_activity.records, trimp: complex_activity.trimp}.to_json
      complex_activity.to_json.should eq serialized_activity
      loaded_activity = AnalyzedActivity.from_json serialized_activity
      loaded_activity.to_json.should eq complex_activity.to_json
    end
  end

  describe "#trimp" do
    subject(:activity) { build :empty_activity, trimp_analyzer: mock("trimp_analyzer") }
    it "should call the trimp analizer when asked for its trimp value" do
      activity.trimp_analyzer.should_receive :trimp
      activity.trimp
    end
  end

  describe "#load and #save" do
    subject(:activity) { build :complex_activity }
    it "should save to redis" do
      activity.save
      activity.redis.get("Activities:#{activity.uri}").should == activity.to_json
    end
    it "should load from redis" do
      activity.save
      loaded_activity = AnalyzedActivity.load activity.uri, activity.redis
      loaded_activity.nil?.should == false
      loaded_activity.to_json.should == activity.to_json
    end
  end

  describe "#cached?" do
    subject(:activity) { build :complex_activity }
    it "should not have cached results when created" do
      activity.cached?.should == false
    end
    it "should not have cached results when only records are computed" do
      activity.records
      activity.cached?.should == false
    end
    it "should not have cached results when only trimp is computed" do
      activity.trimp
      activity.cached?.should == false
    end
    it "should have cached results when trimp and records have been computed" do
      activity.trimp
      activity.records
      activity.cached?.should == true
    end
    it "should have cached results when saved" do
      activity.save
      activity.cached?.should == true
    end
    it "should have cached results when loaded" do
      activity.save
      loaded_activity = AnalyzedActivity.load activity.uri, activity.redis
      loaded_activity.cached?.should == true
    end
    it "should not have cached results when flushed" do
      activity.save
      activity.flush
      activity.cached?.should == false
    end
  end

  describe "#flush" do
    subject(:activity) { build :complex_activity }
    it "should not be cached after being flushed" do
      activity.save
      activity.flush
      activity.cached?.should == false
    end
    it "should not be in redis after being flushed" do
      activity.save
      activity.flush
      AnalyzedActivity.load(activity.uri,activity.redis).nil?.should == true
    end
  end
end
