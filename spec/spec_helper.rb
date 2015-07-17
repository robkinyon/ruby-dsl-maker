RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  minimum_coverage 100
  refuse_coverage_drop
end

require 'dsl/maker'
