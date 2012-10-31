require_relative './rspec_helpers'
require_relative '../lib/tsb_analyzer'
require_relative './factories/tsb_analyzers'

require 'descriptive_statistics'
require 'factory_girl'

describe TsbAnalyzer do
  Settings.instance.resting_heart_rate = 40
  Settings.instance.maximum_heart_rate = 200
  Settings.instance.gender = :male

  describe "#atl" do
    it "should calculate atl for no workouts" do
      tsb_analyzer = build :empty_tsb_analyzer
      tsb_analyzer.atl(Date.new.prev_month, Date.new).each_value { |atl|
        atl.should == 0
      }
    end

    it "should calculate atl for a single workout" do
      tsb_analyzer = build :one_activity_tsb_analyzer
      start_date = tsb_analyzer.activities.first.start_time.to_date
      tsb_analyzer.atl(start_date,start_date+6).should be_close_hash_values({
                                                                              start_date => 11.88,
                                                                              start_date+1 => 8.91,
                                                                              start_date+2 => 6.68,
                                                                              start_date+3 => 5.01,
                                                                              start_date+4 => 3.76,
                                                                              start_date+5 => 2.82,
                                                                              start_date+6 => 2.11
      }, 0.01)
    end

    it "should calculate atl for multiple workouts" do
      tsb_analyzer = build :two_activity_tsb_analyzer
      start_date = tsb_analyzer.activities.first.start_time.to_date
      tsb_analyzer.atl(start_date, start_date+6).should be_close_hash_values({
                                                                               start_date => 11.88,
                                                                               start_date + 1 => 20.79,
                                                                               start_date + 2 => 15.59,
                                                                               start_date + 3 => 11.70,
                                                                               start_date + 4 => 8.77,
                                                                               start_date + 5 => 6.58,
                                                                               start_date + 6 => 4.93
                                                                             }, 0.01)
    end
  end

  describe "#ctl" do
    it "should calculate ctl for no workouts" do
      tsb_analyzer = build :empty_tsb_analyzer
      tsb_analyzer.ctl(Date.new.prev_month, Date.new).each_value { |ctl|
        ctl.should == 0
      }
    end
    it "should calculate ctl for a single workout" do
      tsb_analyzer = build :one_activity_tsb_analyzer
      start_date = tsb_analyzer.activities.first.start_time.to_date
      tsb_analyzer.ctl(start_date, start_date+4).should be_close_hash_values({
                                                                                start_date => 4.42,
                                                                                start_date + 1 => 4.22,
                                                                                start_date + 2 => 4.02,
                                                                                start_date + 3 => 3.83,
                                                                                start_date + 4 => 3.65
                                                                              }, 0.01)
    end
    it "should calculate ctl for multiple workouts" do
      tsb_analyzer = build :two_activity_tsb_analyzer
      start_date = tsb_analyzer.activities.first.start_time.to_date
      tsb_analyzer.ctl(start_date, start_date+6).should be_close_hash_values({
                                                                               start_date => 4.42,
                                                                               start_date + 1 => 8.64,
                                                                               start_date + 2 => 8.23,
                                                                               start_date + 3 => 7.85,
                                                                               start_date + 4 => 7.49,
                                                                               start_date + 5 => 7.14,
                                                                               start_date + 6 => 6.81
                                                                             }, 0.01)
    end
  end

  describe "#monotony" do
    it "should calculate monotony if no workouts have been completed" do
      tsb_analyzer = build :empty_tsb_analyzer
      tsb_analyzer.monotony(Date.new).should == 0.0
    end
    it "should calculate monotony for a single workout in a week" do
      tsb_analyzer = build :one_activity_tsb_analyzer
      start_date = tsb_analyzer.activities.first.start_time.to_date
      tsb_analyzer.monotony(start_date + 4).should be_within(0.01).of(0.41)
    end
    it "should calculate monotony for multiple workouts in a week" do
      tsb_analyzer = build :two_activity_tsb_analyzer
      start_date = tsb_analyzer.activities.first.start_time.to_date
      tsb_analyzer.monotony(start_date + 4).should be_within(0.01).of(0.63)
    end
  end
end
