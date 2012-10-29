require 'singleton'

class Settings
  include Singleton
  attr_accessor :resting_heart_rate, :maximum_heart_rate, :gender
end
