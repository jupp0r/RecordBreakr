class RecordAnalyzer

  def initialize distance_vector, distances
    @distance_vector = distance_vector
    @distances = distances
  end

  def records
    return nil if @distance_vector.empty?
    record_list = Hash.new
    @distances.each do |distance|
      record = calculate_record_for_distance distance
      record_list[distance] = record if record[:time] < Float::INFINITY
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
    global_minimum = {:time => Float::INFINITY, :start => 0.0, :stop => 0.0}
    relevant_distance_points = @distance_vector.find_all { |point| point['distance'] >= distance }
    relevant_distance_points.each do |end_point|
      start_time = interpolate_time_for_distance(end_point['distance'] - distance)
      race_time = end_point['timestamp'] - start_time
      global_minimum = {:time => race_time, :start => start_time, :stop => end_point['timestamp']} if race_time < global_minimum[:time]
    end
    global_minimum
  end

end
