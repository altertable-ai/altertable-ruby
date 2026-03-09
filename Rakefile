# frozen_string_literal: true

require "rspec/core/rake_task"
require "bundler/gem_tasks"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

task default: %i[spec rubocop]
