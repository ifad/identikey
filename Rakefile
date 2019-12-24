require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = '-f doc'
end

task :default => :spec

require 'code_counter/engine'
desc 'Print code statistics'
task :stats do
  puts CodeCounter::Engine.new.to_s
end
