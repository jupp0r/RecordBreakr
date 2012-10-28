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
end
