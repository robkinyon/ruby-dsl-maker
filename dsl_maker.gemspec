require File.expand_path('on_what', File.dirname(__FILE__))
$:.push File.expand_path('../lib', __FILE__)
require 'dsl/maker/version'

Gem::Specification.new do |s|
  s.name    = 'dsl::maker'
  s.version = DSL::Maker::VERSION
  s.author  = 'Rob Kinyon'
  s.email   = 'rob.kinyon@gmail.com'
  s.summary = 'Easy multi-level DSLs, built on top of Docile'
  s.license = 'GPL2'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = []
  s.require_paths = %w(lib)

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'docile'

  # Run rspec tests from rake
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.0.0'
  s.add_development_dependency 'simplecov'

  # To limit needed compatibility with versions of dependencies, only configure
  #   yard doc generation when *not* on Travis, JRuby, or 1.8
  if !on_travis? && !on_jruby? && !on_1_8?
    # Github flavored markdown in YARD documentation
    # http://blog.nikosd.com/2011/11/github-flavored-markdown-in-yard.html
    s.add_development_dependency 'yard'
    s.add_development_dependency 'redcarpet'
    s.add_development_dependency 'github-markup'
  end
end
