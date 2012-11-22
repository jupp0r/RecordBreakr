class AnalyzedTimeline
  attr_accessor :activies

  def initialize activities
    @activities = activities.sort_by {|activity| activity.start_time}
    @tsb_analyzer = TsbAnalyzer.new @activities
  end

  def atl
    @tsb_analyzer.atl analysis_start_date, Date.today
  end

  def ctl
    @tsb_analyzer.ctl analysis_start_date, Date.today
  end

  def ctl_minus_atl
    atl_vec = atl
    ctl_vec = ctl
    ctl.each_with_object({}) {|(date, ctl), h| h[date] = ctl - atl_vec[date]}
  end

  def analysis_start_date
    @activities.first.start_time.to_date
  end

  def maximum_cumulative_distances period_in_days
    maximum_distances = Hash.new
    period_in_days.each do |period|
      maximum_distances[period] = find_maximum_activity_distance period
    end
    maximum_distances
  end

  def records
    distances = Settings.instance.record_distances
    records = Hash.new
    distances.each do |distance|
      records[distance] = Array.new
    end
    @activities.each do |activity|
      activity_records = activity.records
      activity_records.each_pair do |distance, record|
        next if not distances.member? distance
        next if record.nil?
        records[distance] << {activity: activity, record: record}
      end
    end
    records.each do |distance, record_array|
      record_array.sort_by!{|r| r[:record][:time]}
    end
    records
  end

  private

  def find_maximum_activity_distance period
    maximum_distance = 0
    maximum_activities = []
    @activities.each do |late_activity|
      temp_distance = late_activity.distance
      temp_activities = [late_activity]
      @activities.each do |early_activity|
        next if late_activity == early_activity
        delta_t = late_activity.start_time.to_date - early_activity.start_time.to_date
        next unless delta_t > 0
        if delta_t <= period - 1
          temp_distance = temp_distance + early_activity.distance
          temp_activities << early_activity
        end
      end
      if temp_distance > maximum_distance
        maximum_distance = temp_distance
        maximum_activities = temp_activities
      end
    end
    maximum_activities.sort_by! { |activity| activity.start_time }
    {distance: maximum_distance, activities: maximum_activities}
  end
end
