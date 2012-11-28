class AnalyzedTimeline
  attr_accessor :activities

  def initialize activity_uris
    @activity_uris = activity_uris
    load_activities activity_uris
    @activities.sort_by! do |activity|
      if activity != :analyzing
        activity.start_time
      else
        DateTime.new
      end
    end
    @tsb_analyzer = TsbAnalyzer.new @activities
  end

  def refresh_activities!
    load_activities @activity_uris
  end

  def atl
    return :in_progress unless progress == :all_done
    @tsb_analyzer.atl analysis_start_date, Date.today
  end

  def ctl
    return :in_progress unless progress == :all_done
    @tsb_analyzer.ctl analysis_start_date, Date.today
  end

  def ctl_minus_atl
    return :in_progress unless progress == :all_done
    atl_vec = atl
    ctl_vec = ctl
    ctl.each_with_object({}) {|(date, ctl), h| h[date] = ctl - atl_vec[date]}
  end

  def analysis_start_date
    return :in_progress unless progress == :all_done
    @activities.first.start_time.to_date
  end

  def maximum_cumulative_distances period_in_days
    return :in_progress unless progress == :all_done
    maximum_distances = Hash.new
    period_in_days.each do |period|
      maximum_distances[period] = find_maximum_activity_distance period
    end
    maximum_distances
  end

  def records
    if progress == :all_done
      prepare_records
    else
      maybe_launch_analyzers
      :in_progress
    end
  end

  def progress
    refresh_activities!
    number_activities_done = 0
    number_activities = @activities.size
    @activities.each do |activity|
      number_activities_done += 1 if activity != :analyzing
    end
    if number_activities_done == number_activities
      :all_done
    else
      {done: number_activities_done, all: number_activities}
    end
  end

  private

  def prepare_records
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

  def maybe_launch_analyzers
    @activities.each do |activity|
      activity.start_analyzer! unless activity == :analyzing or activity.analyzed?
    end
  end

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

  def load_activities activity_uris
    @activities = Array.new
    activity_uris.each do |activity_uri|
      if AnalyzedActivity.analyzed? activity_uri
        @activities << AnalyzedActivity.load(activity_uri)
      else
        if not AnalyzedActivity.analyzing? activity_uri
          Resque.enqueue Analyzer, activity_uri, Settings.instance.to_hash
        end
        @activities << :analyzing
      end
    end
  end
end
