require "bundler/gem_tasks"
require "rspec/core/rake_task"

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = %w[-fd]
  end

  task default: :spec
rescue LoadError
end
