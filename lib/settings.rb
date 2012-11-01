require 'singleton'

class Settings
  include Singleton
  attr_accessor :resting_heart_rate, :maximum_heart_rate, :gender, :record_distances

  def to_hash
    {:resting_heart_rate => @resting_heart_rate, :maximum_heart_rate => @maximum_heart_rate, :gender => @gender, :record_distances => @record_distances}
  end

  def self.load_from_hash settings_hash
    symbol_hash = settings_hash.each_with_object({}){|(k,v), h| h[k.to_sym] = v}
    self.instance.resting_heart_rate = symbol_hash[:resting_heart_rate]
    self.instance.maximum_heart_rate = symbol_hash[:maximum_heart_rate]
    self.instance.gender = symbol_hash[:gender].to_sym
    self.instance.record_distances = symbol_hash[:record_distances]
  end
end
