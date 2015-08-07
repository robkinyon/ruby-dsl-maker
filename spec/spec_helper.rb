require File.expand_path('on_what', File.dirname(File.dirname(__FILE__)))

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

unless on_1_8?
  begin
    require 'simplecov'

    SimpleCov.configure do
      add_filter '/spec/'
      add_filter '/vendor/'
      minimum_coverage 100
      refuse_coverage_drop
    end

    if on_travis?
      require 'codecov'
      SimpleCov.formatter = SimpleCov::Formatter::Codecov
    end

    SimpleCov.start
  rescue LoadError
    puts "Coverage is disabled - install simplecov to enable."
  end
end

require 'dsl/maker'

module Structs
  Car = Struct.new(:maker, :wheel)
  Truck = Struct.new(:maker, :wheel)
  Wheel = Struct.new(:maker, :size)

  Person = Struct.new(:name, :child)
  OtherPerson = Struct.new(:name, :mother, :father)

  $toppings = [:cheese, :pepperoni, :bacon, :sauce]
  Pizza = Struct.new(*$toppings)

  Color = Struct.new(:name)
  Fruit = Struct.new(:name, :color)
end

