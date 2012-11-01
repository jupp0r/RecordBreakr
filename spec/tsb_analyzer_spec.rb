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
      start_date = tsb_analyzer.first_activity_date
      tsb_analyzer.atl(start_date,start_date+6).should be_close_hash_values({
                                                                              start_date => 4.81,
                                                                              start_date+1 => 4.04,
                                                                              start_date+2 => 3.40,
                                                                              start_date+3 => 2.86,
                                                                              start_date+4 => 2.40,
                                                                              start_date+5 => 2.02,
                                                                              start_date+6 => 1.70
      }, 0.01)
    end

    it "should calculate atl for multiple workouts" do
      tsb_analyzer = build :two_activity_tsb_analyzer
      start_date = tsb_analyzer.first_activity_date
      tsb_analyzer.atl(start_date, start_date+6).should be_close_hash_values({
                                                                               start_date => 4.81,
                                                                               start_date + 1 => 9.96,
                                                                               start_date + 2 => 8.19,
                                                                               start_date + 3 => 6.73,
                                                                               start_date + 4 => 5.54,
                                                                               start_date + 5 => 4.55,
                                                                               start_date + 6 => 3.74
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
      start_date = tsb_analyzer.first_activity_date
      tsb_analyzer.ctl(start_date, start_date+4).should be_close_hash_values({
                                                                                start_date => 2.81,
                                                                                start_date + 1 => 2.68,
                                                                                start_date + 2 => 2.56,
                                                                                start_date + 3 => 2.44,
                                                                                start_date + 4 => 2.32
                                                                              }, 0.01)
    end
    it "should calculate ctl for multiple workouts" do
      tsb_analyzer = build :two_activity_tsb_analyzer
      start_date = tsb_analyzer.first_activity_date
      tsb_analyzer.ctl(start_date, start_date+6).should be_close_hash_values({
                                                                               start_date => 2.81,
                                                                               start_date + 1 => 5.82,
                                                                               start_date + 2 => 5.55,
                                                                               start_date + 3 => 5.29,
                                                                               start_date + 4 => 5.05,
                                                                               start_date + 5 => 4.82,
                                                                               start_date + 6 => 4.59
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
      start_date = tsb_analyzer.first_activity_date
      tsb_analyzer.monotony(start_date + 4).should be_within(0.01).of(0.41)
    end
    it "should calculate monotony for multiple workouts in a week" do
      tsb_analyzer = build :two_activity_tsb_analyzer
      start_date = tsb_analyzer.first_activity_date
      tsb_analyzer.monotony(start_date + 4).should be_within(0.01).of(0.63)
    end
  end

  describe "#training_strain" do
    it "should calculate training strain if no workouts have been completed" do
      tsb_analyzer = build :empty_tsb_analyzer
      tsb_analyzer.training_strain(Date.new).should == 0.0
    end
    it "should calculate training strain for a single workout in a week" do
      tsb_analyzer = build :one_activity_tsb_analyzer
      start_date = tsb_analyzer.first_activity_date
      tsb_analyzer.training_strain(start_date + 4).should be_within(0.1).of(19.4)
    end
    it "should calculate training strain for multiple workouts in a week" do
      tsb_analyzer = build :two_activity_tsb_analyzer
      start_date = tsb_analyzer.first_activity_date
      tsb_analyzer.training_strain(start_date+4).should be_within(0.1).of(60.1)
    end
  end
end
