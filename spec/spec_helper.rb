require 'simplecov'

RSpec.configure do |config|
  SimpleCov.start do
    minimum_coverage 100
    refuse_coverage_drop
  end
end

require 'dsl/maker'
