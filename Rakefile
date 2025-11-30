# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ["lib/**/*.rb", "spec/**/*.rb"]
  task.fail_on_error = true
end

task default: [:spec, :rubocop]
