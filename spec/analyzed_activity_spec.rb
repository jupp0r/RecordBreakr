require_relative '../lib/analyzed_activity'
require_relative './factories/analyzed_activities'
require_relative './rspec_helpers'

describe AnalyzedActivity do

  describe "#records" do
    subject(:activity) { build :empty_activity, record_analyzer: mock("record_analyzer") }
    it "should use the RecordAnalyzer to analize records"  do
      activity.should_receive :records
      activity.records
    end
  end

  describe "#serialize" do
    subject(:activity) { FactoryGirl.build :empty_activity }
    it "should serialize to json and save to redis" do
      activity.persist.should === "{\"uri\":\"\",\"type\":\"\",\"start_time\":\"1970-01-01 01:00:00 +0100\",\"duration\":0,\"distance\":0,\"distance_vector\":\"[]\",\"heart_rate\":0,\"heart_rate_vector\":[],\"calories\":0,\"notes\":\"\",\"gps_path\":\"[]\"}"
    end
  end

  describe "#load" do
    it "should load empty activity from json" do
      created_activity = FactoryGirl.build :empty_activity
      serialized_activity = "{\"uri\":\"\",\"type\":\"\",\"start_time\":\"1970-01-01 01:00:00 +0100\",\"duration\":0,\"distance\":0,\"distance_vector\":\"[]\",\"heart_rate\":0,\"heart_rate_vector\":[],\"calories\":0,\"notes\":\"\",\"gps_path\":\"[]\"}"
      created_activity.persist.should eq serialized_activity
      loaded_activity = AnalyzedActivity.load serialized_activity
      loaded_activity.persist.should eq created_activity.persist
    end
    it "should load filled activity" do
      complex_activity = FactoryGirl.build :complex_activity
      serialized_activity = "{\"uri\":\"\",\"type\":\"\",\"start_time\":\"1970-01-01 01:00:00 +0100\",\"duration\":0,\"distance\":0,\"distance_vector\":\"[{\\\"timestamp\\\":0.0,\\\"distance\\\":0.0},{\\\"timestamp\\\":5.0,\\\"distance\\\":1.0},{\\\"timestamp\\\":10.0,\\\"distance\\\":1001.0},{\\\"timestamp\\\":15.0,\\\"distance\\\":1002.0}]\",\"heart_rate\":0,\"heart_rate_vector\":[{\"timestamp\":0.0,\"heart_rate\":150},{\"timestamp\":600.0,\"heart_rate\":155},{\"timestamp\":1200.0,\"heart_rate\":145},{\"timestamp\":1800.0,\"heart_rate\":140}],\"calories\":0,\"notes\":\"\",\"gps_path\":\"[]\"}"
      complex_activity.persist.should eq serialized_activity
      loaded_activity = AnalyzedActivity.load serialized_activity
      loaded_activity.persist.should eq complex_activity.persist
    end
  end

  describe "#trimp" do
    subject(:activity) { build :empty_activity, trimp_analyzer: mock("trimp_analyzer") }
    it "should call the trimp analizer when asked for its trimp value" do
      activity.trimp_analyzer.should_receive :trimp
      activity.trimp
    end
  end
end
