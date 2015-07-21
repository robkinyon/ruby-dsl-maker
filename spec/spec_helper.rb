RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

begin
  require 'simplecov'

  SimpleCov.configure do
    add_filter '/spec/'
    minimum_coverage 100
    refuse_coverage_drop
  end

  SimpleCov.start
rescue LoadError
  puts "Coverage is disabled - install simplecov to enable."
end

require 'dsl/maker'
