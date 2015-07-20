require 'rake/clean'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

# This is used by the Yardoc stuff in docile's Rakefile. We're not there yet.
#require File.expand_path('on_what', File.dirname(__FILE__))

# Default task for `rake` is to run rspec
task :default => [:spec]

# Use default rspec rake task
RSpec::Core::RakeTask.new

# Configure `rake clobber` to delete all generated files
CLOBBER.include('pkg', 'doc', 'coverage')
