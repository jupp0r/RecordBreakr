require_relative '../lib/record_analyzer'

describe RecordAnalyzer do
  describe "#calculate_fastest_distances" do
    it "returns an empty record list for an empty track" do
      distance_vector = []
      distances = [1000]
      record_analyzer = RecordAnalyzer.new distance_vector, distances
      record_analyzer.records.should.nil?
    end

    it "returns the distance and time for a track of the exact distance" do
      record_time = 5.0
      record_distance = 1000
      distance_vector = [{'timestamp' => 0.0, 'distance' => 0.0},
                         {'timestamp' => record_time, 'distance' => record_distance}]
      distances = [record_distance]
      record_analyzer = RecordAnalyzer.new distance_vector, distances
      record_analyzer.records.should == {1000 => {:time => record_time, :start => 0.0, :stop => record_time}}
    end

    it "returns the distance and time for a track where the distance is between two track points" do
      distance_vector = [
                         {'timestamp' => 0.0, 'distance' => 0.0},
                         {'timestamp' => 5.0, 'distance' => 1.0},
                         {'timestamp' => 10.0, 'distance' => 1001.0},
                         {'timestamp' => 15.0, 'distance' => 1002.0}
                        ]
      distances = [1000]
      record_analyzer = RecordAnalyzer.new distance_vector, distances
      record_analyzer.records.should == {1000 => {:time => 5.0, :start => 5.0, :stop => 10.0}}
    end
  end
end
