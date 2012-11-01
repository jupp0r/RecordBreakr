require 'factory_girl'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

# stolen from http://stackoverflow.com/questions/6855944/rounding-problem-with-rspec-tests-when-comparing-float-arrays
RSpec::Matchers.define :be_close_hash_values do |expected, delta|
  match do |actual|
    number_of_matching_kv_pairs = 0
    actual.each_key do |key|
      number_of_matching_kv_pairs = number_of_matching_kv_pairs + 1 if (expected.has_key? key) and (actual[key] - expected[key]).abs <= delta
    end
    number_of_matching_kv_pairs == actual.length and number_of_matching_kv_pairs == expected.length
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would be close to #{expected}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not be close to #{expected}"
  end

  description do
        "be a close to #{expected}"
  end
end
