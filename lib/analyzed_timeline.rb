class AnalyzedTimeline
  attr_accessor :activies

  def initialize activities
    @activities = activities.sort_by {|activity| activity.start_time}
    @tsb_analyzer = TsbAnalyzer.new @activities
  end

  def atl
    start_date = @activities.first.start_time.to_date
    @tsb_analyzer.atl start_date, Date.today
  end
end
