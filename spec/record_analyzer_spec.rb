require 'factory_girl'
require_relative '../lib/record_analyzer.rb'

describe RecordAnalyzer do
  describe "#interpolate_time_for_distance" do
    it "should interpolate nothing for an empty distance vector" do
      record_analyzer = RecordAnalyzer.new [], []
      record_analyzer.interpolate_time_for_distance(0.0).should.nil?
    end

    it "should interpolate linearly between two points" do
      record_analyzer = RecordAnalyzer.new [{'timestamp' => 0.0, 'distance' => 0.0},{'timestamp' => 2.0, 'distance' => 8.0}], []
      record_analyzer.interpolate_time_for_distance(4.0).should == 1.0
    end
  end

  describe "#records" do
    it "should give an empty record list for an empty distance vector" do
      record_analyzer = RecordAnalyzer.new [], []
      record_analyzer.records.should.nil?
    end

    it "should give a record if the distance vector contains that record for two consecutive points" do
      record_analyzer = RecordAnalyzer.new [{'timestamp' => 0.0, 'distance' => 0.0}, {'timestamp' => 500.0, 'distance' => 1000.0}], [1000]
      record_analyzer.records.should == {1000 => {:start => 0.0, :stop => 500.0, :time => 500.0}}
    end

    it "should interpolate between points" do
      record_analyzer = RecordAnalyzer.new [{'timestamp' => 0.0, 'distance' => 0.0},
                                            {'timestamp' => 2.0, 'distance' => 2000.0}], [1000]
      record_analyzer.records.should == {1000 => {:start => 1.0, :stop => 2.0, :time => 1.0}}
    end

    it "should find records in the middle of a track" do
      record_analyzer = RecordAnalyzer.new [{'timestamp' => 0.0, 'distance' => 0.0},
                                            {'timestamp' => 750.0, 'distance' => 750.0},
                                            {'timestamp' => 1500.0, 'distance' => 2250.0},
                                            {'timestamp' => 2000.0, 'distance' => 2350.0}], [1000]
      record_analyzer.records.should == {1000 => {:start => 1000.0, :stop => 1500.0, :time => 500.0}}
    end

    it "should return no records if the distance is too low for any record distance" do
      record_analyzer = RecordAnalyzer.new [{'timestamp' => 0.0, 'distance' => 0.0}, {'timestamp' => 1.0, 'distance' => 1.0}], [1000]
      record_analyzer.records.should == {}
    end

  end

end
