require File.expand_path('on_what', File.dirname(__FILE__))
$:.push File.expand_path('../lib', __FILE__)
require 'dsl/maker/version'

Gem::Specification.new do |s|
  s.name    = 'dsl::maker'
  s.version = DSL::Maker::VERSION
  s.author  = 'Rob Kinyon'
  s.email   = 'rob.kinyon@gmail.com'
  s.summary = 'Easy multi-level DSLs, built on top of Docile'

  s.required_ruby_version = '>= 1.8.7'

  s.add_dependency 'docile'

  # Run rspec tests from rake
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.0.0'
  s.add_development_dependency 'simplecov'

  # NOTE: needed for Travis builds on 1.8, but can't yet reproduce failure locally
  s.add_development_dependency 'mime-types' , '~> 1.25.1' if on_1_8?
  s.add_development_dependency 'rest-client', '~> 1.6.8'  if on_1_8?
end
