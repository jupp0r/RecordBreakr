class TsbAnalyzer
  def initialize activities
    @activities = activities
  end

  def atl start_date, end_date
    atl_values = Hash.new
    atl_yesterday = 0
    lambda_a = 2.0/(7+1)
    k_a = 1.0
    start_date.upto end_date do |day|
      trimp_today = 0.0
      @activities.find_all{|activity| activity.start_time.to_date == day}.each do |activity|
        trimp_today = trimp_today + activity.trimp
      end
      atl_today = trimp_today * lambda_a * k_a + ((1.0 - lambda_a) * atl_yesterday)
      atl_yesterday = atl_today
      atl_values[day] = atl_today
    end
    atl_values
  end
end
