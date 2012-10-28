class RecordAnalyzer

  def initialize distance_vector, distances
    @distance_vector = distance_vector
    @distances = distances
  end

  def records
    return nil if @distance_vector.empty?
    record_list = Hash.new
    @distances.each do |distance|
      record_list[distance] = calculate_record_for_distance distance
    end
    record_list
  end

  def interpolate_time_for_distance distance
    return nil if @distance_vector.empty?

    latest_entry_index = @distance_vector.find_index do |entry|
      entry['distance'] >= distance
    end

    latest_entry = @distance_vector[latest_entry_index]
    before_entry = @distance_vector[latest_entry_index-1]

    distance_ratio = (latest_entry['distance'] - distance) / (latest_entry['distance'] - before_entry['distance'])
    target_time = latest_entry['timestamp'] - (latest_entry['timestamp'] - before_entry['timestamp']) * distance_ratio
  end

  private
  def calculate_record_for_distance distance
    {:time => @distance_vector.last["timestamp"], :start => @distance_vector.first["timestamp"], :stop => @distance_vector.last["timestamp"]}
  end

end
