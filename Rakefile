require 'rake/clean'
require 'bundler/gem_tasks'
require 'rubygems/tasks'
require 'rspec/core/rake_task'

# This is used by the Yardoc stuff in docile's Rakefile. We're not there yet.
require File.expand_path('on_what', File.dirname(__FILE__))

# Default task for `rake` is to run rspec
task :default => [:spec]

# Use default rspec rake task
RSpec::Core::RakeTask.new

# Configure `rake clobber` to delete all generated files
CLOBBER.include('pkg', 'doc', 'coverage', '*.gem')

# Add the gem tasks:
# :build, :console, :install, :release
Gem::Tasks.new

if !on_travis? && !on_jruby? && !on_1_8?
  require 'github/markup'
  require 'redcarpet'
  require 'yard'
  require 'yard/rake/yardoc_task'

  YARD::Rake::YardocTask.new do |t|
    OTHER_PATHS = %w()
    t.files   = ['lib/**/*.rb', OTHER_PATHS]
    t.options = %w(--markup-provider=redcarpet --markup=markdown --main=README.md)
  end
end
