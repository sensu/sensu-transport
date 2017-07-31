require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

begin
  require "github_changelog_generator/task"
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.issues = false
  end
rescue LoadError
  puts ">>> Gem load error: #{e},  omitting #{task.name}"
end

task :default => :spec
