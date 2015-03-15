namespace :helpdesk do
  desc 'Runs Redmine plugin tests with single CodeClimate TestReporter invocation.'
  task :test do

    Rake::Task["redmine:plugins:test:units"].invoke
    Rake::Task["redmine:plugins:test:functionals"].invoke

    require "simplecov"
    require "codeclimate-test-reporter"
    SimpleCov.coverage_dir "plugins/coverage"
    CodeClimate::TestReporter.configure do |config|
      config.git_dir = "plugins/#{ENV['GITHUB_PROJECT']}"
    end
    CodeClimate::TestReporter::Formatter.new.format(SimpleCov.result)
  end
end
