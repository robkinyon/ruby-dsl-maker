require File.expand_path('on_what', File.dirname(__FILE__))
$:.push File.expand_path('../lib', __FILE__)
require 'dsl/maker/version'

Gem::Specification.new do |s|
  s.name    = 'dsl::maker'
  s.version = DSL::Maker::VERSION
  s.author  = 'Rob Kinyon'
  s.email   = 'rob.kinyon@gmail.com'
  s.summary = 'Easy multi-level DSLs, built on top of Docile'

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'docile'

  # Run rspec tests from rake
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.0.0'
  s.add_development_dependency 'simplecov'
end
