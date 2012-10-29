class TrimpAnalyzer
  def initialize heart_rate_vector, resting_heart_rate, maximum_heart_rate, gender
    @heart_rate_vector = heart_rate_vector
    @resting_heart_rate = resting_heart_rate
    @maximum_heart_rate = maximum_heart_rate
    @gender = gender
    @scaling_factor = Hash.new
    @scaling_factor[:male] = 1.92
    @scaling_factor[:female] = 1.67
  end

  # formula taken from http://fellrnr.com/wiki/TRIMP
  def trimp
    trimp = 0.0
    @heart_rate_vector.each_cons(2) do |hr_point_early, hr_point_late|
      delta_t = hr_point_late['timestamp'] - hr_point_early['timestamp']
      average_heart_rate = (hr_point_early['heart_rate'] + hr_point_late['heart_rate'])/2
      heart_rate_fraction = (average_heart_rate.to_f - @resting_heart_rate.to_f)/(@maximum_heart_rate.to_f - @resting_heart_rate.to_f)
      trimp = trimp + (delta_t/60.0) * heart_rate_fraction * 0.64 * Math.exp(heart_rate_fraction * @scaling_factor[@gender])
    end
    trimp
  end
end
