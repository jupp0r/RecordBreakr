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


end
