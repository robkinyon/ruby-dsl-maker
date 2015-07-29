require File.expand_path('on_what', File.dirname(__FILE__))
$:.push File.expand_path('../lib', __FILE__)
require 'dsl/maker/version'

Gem::Specification.new do |s|
  s.name    = 'dsl_maker'
  s.version = DSL::Maker::VERSION
  s.author  = 'Rob Kinyon'
  s.email   = 'rob.kinyon@gmail.com'
  s.summary = 'Easy multi-level DSLs'
  s.description = 'Easy multi-level DSLs, built on top of Docile'
  s.license = 'GPL2'
  s.homepage = 'https://github.com/robkinyon/ruby-dsl-maker'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = []
  s.require_paths = %w(lib)

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'docile', '~> 1.1', '>= 1.1.0'

  # Run rspec tests from rake
  s.add_development_dependency 'rake', '~> 10'
  s.add_development_dependency 'rspec', '~> 3.0.0', '>= 3.0.0'
  s.add_development_dependency 'simplecov', '~> 0'
  s.add_development_dependency 'rubygems-tasks', '~> 0'

  # To limit needed compatibility with versions of dependencies, only configure
  #   yard doc generation when *not* on Travis, JRuby, or 1.8
  if !on_travis? && !on_jruby? && !on_1_8?
    # Github flavored markdown in YARD documentation
    # http://blog.nikosd.com/2011/11/github-flavored-markdown-in-yard.html
    s.add_development_dependency 'yard', '~> 0.8'
    s.add_development_dependency 'redcarpet', '~> 3'
    s.add_development_dependency 'github-markup', '~> 1.3'
  end
end
