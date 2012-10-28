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

  describe "#persist" do
    subject(:activity) { build :empty_activity }
    it "should serialize to json" do
      activity.persist.should === "{\"uri\":\"\",\"type\":\"\",\"start_time\":\"1970-01-01 01:00:00 +0100\",\"duration\":0,\"distance\":0,\"distance_vector\":\"[]\",\"heart_rate\":0,\"heart_rate_vector\":[],\"calories\":0,\"notes\":\"\",\"gps_path\":\"[]\"}"
    end
  end
end
