require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = "-c --format documentation #{ENV['TEST_OPTS']}"
  end
rescue LoadError
end

