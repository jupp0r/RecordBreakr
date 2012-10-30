require 'descriptive_statistics/safe'

class TsbAnalyzer
  def initialize activities
    @activities = activities
  end

  def atl start_date, end_date
    atl_values = Hash.new
    atl_yesterday = 0.0
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

  def ctl start_date, end_date
    ctl_values = Hash.new
    lambda_f = 2.0/(42+1)
    k_f = 2.0
    ctl_yesterday = 0.0
    start_date.upto end_date do |day|
      trimp_today = 0.0
      @activities.find_all{|activity| activity.start_time.to_date == day}.each do |activity|
        trimp_today = trimp_today + activity.trimp
      end
      ctl_today = trimp_today * lambda_f * k_f + ((1.0 - lambda_f) * ctl_yesterday)
      ctl_yesterday = ctl_today
      ctl_values[day] = ctl_today
    end
    ctl_values
  end

  def monotony date
    return 0.0 if @activities.empty?
    trimp_vector = []
    (date-6).upto date do |day|
      trimp_today = 0.0
      @activities.find_all{|activity| activity.start_time.to_date == day}.each do |activity|
        trimp_today = trimp_today + activity.trimp
      end
      trimp_vector.push trimp_today
    end
    trimp_vector.extend(DescriptiveStatistics)
    trimp_vector.mean / trimp_vector.standard_deviation
  end
end
