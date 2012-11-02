require 'descriptive_statistics/safe'

class TsbAnalyzer
  attr_accessor :activities

  def initialize activities
    @activities = activities
  end

  def atl start_date, end_date
    atl_values = Hash.new
    atl_yesterday = 0.0
    lambda_a = 2.0/(7+1)
    k_a = 1.0
    start_date.upto end_date do |day|
      atl_today = trimp_am(day) * fatigue_lambda_a(lambda_a, day) * k_a + ((1.0 - fatigue_lambda_a(lambda_a, day)) * atl_yesterday)
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
      ctl_today = trimp_cm(day) * lambda_f * k_f + ((1.0 - lambda_f) * ctl_yesterday)
      ctl_yesterday = ctl_today
      ctl_values[day] = ctl_today
    end
    ctl_values
  end

  def monotony date
    return 0.0 if @activities.empty?
    monotony_cap = 10.0
    trimp_vector = []
    (date-6).upto date do |day|
      trimp_vector.push(trimp_for_day day)
    end
    trimp_vector.extend(DescriptiveStatistics)
    monotony_raw = trimp_vector.mean / trimp_vector.standard_deviation
    if monotony_raw.nan? or monotony_raw > monotony_cap
      monotony_cap
    else
      monotony_raw
    end
  end

  def training_strain date
    return 0.0 if @activities.empty?
    trimp_sum = 0.0
    (date-6).upto date do |day|
      trimp_sum = trimp_sum + trimp_for_day(day)
    end
    trimp_sum * monotony(date)
  end

  def first_activity_date
    @activities.first.start_time.to_date
  end

  private

  def trimp_for_day day
    trimp_today = 0.0
    @activities.find_all{|activity| activity.start_time.to_date == day}.each do |activity|
      trimp_today = trimp_today + activity.trimp
    end
    trimp_today
  end

  def monotony_ratio date
    monotony_break_even = 1.5
    monotony_cap = 4.0
    [monotony(date),monotony_cap].sort[0] / monotony_break_even
  end

  def fatigue_lambda_a lambda_a, date
    atl_m_lambda_factor = 0.5
    lambda_a * monotony_ratio(date) * atl_m_lambda_factor + (lambda_a * (1 - atl_m_lambda_factor))
  end

  def trimp_am date
    atl_m_stress_factor = 0.5
    trimp = trimp_for_day(date)
    trimp * monotony_ratio(date) * atl_m_stress_factor + (trimp * (1 - atl_m_stress_factor))
  end

  def trimp_cm date
    # hack for now, the constants are the same, although this might be modified later
    trimp_am date
  end
end
