require_relative './rspec_helpers'
require_relative '../lib/trimp_analyzer'

describe TrimpAnalyzer do
  describe "trimp" do
    it "should return a trimp of 0 if no heart rate data is available" do
      trimp_analyzer = TrimpAnalyzer.new [], 50, 185, :male
      trimp_analyzer.trimp.should == 0.0
    end

    it "should correctly calculate trimp for a constant heart rate workout for a male athlete" do
      trimp_analyzer = TrimpAnalyzer.new [{'timestamp' => 0.0, 'heart_rate' => 130},{'timestamp' => 30*60.0, 'heart_rate' => 130}], 40, 200, :male
      trimp_analyzer.trimp.should be_within(0.05).of(31.8)
    end
  end
end
