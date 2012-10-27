class RecordAnalyzer

  def initialize distance_vector, distances
    @distance_vector = distance_vector
    @distances = distances
  end

  def records
    return nil if @distance_vector.empty?
    record_list = Hash.new
    @distances.each do |distance|
      record_list[distance] = {:time => @distance_vector.last["timestamp"], :start => @distance_vector.first["timestamp"], :stop => @distance_vector.last["timestamp"]}
    end
    record_list
  end

end
