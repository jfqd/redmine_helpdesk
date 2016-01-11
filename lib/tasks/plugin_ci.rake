namespace :helpdesk do
  plugin_root = File.expand_path('../../../', __FILE__)
  coverage_dir = "#{plugin_root}/coverage"

  desc 'Runs :ci target from plugin scope in test/app'
  task :ext_ci do
    cd('test/app') do
      sh('bundle exec rake helpdesk:ci')
    end
  end

  desc 'Prepared and configures DB in Docker container'
  task :prepare_local => ['helpdesk:localdb:start',
                          'helpdesk:redmine:configure_db'] do
    Rake::Task['helpdesk:install'].invoke()
  end

  desc 'Runs bundle install from plugin scop in test/app'
  task :install do
    cd('test/app') do
      sh('bundle install --without production development rmagick')
    end
  end

  desc 'Runs migrate from plugin scope in test/app'
  task :migrate do
    cd('test/app') do
      sh('bundle exec rake generate_secret_token')
      sh('bundle exec rake db:migrate')
    end
  end

  desc 'Prepares and runs the test suite.'
  task :ci => ['redmine:plugins:migrate',
               'helpdesk:test']

  desc 'Runs Redmine plugin tests with single CodeClimate TestReporter invocation.'
  task :test => [ 'helpdesk:test:clear_coverage_data',
                  'helpdesk:test:run' ]

  namespace :test do
    task :run do
      Rake::Task['redmine:plugins:test:units'].invoke
      Rake::Task['redmine:plugins:test:functionals'].invoke

      require "simplecov"
      require "codeclimate-test-reporter"
      SimpleCov.coverage_dir "plugins/coverage"
      CodeClimate::TestReporter.configure do |config|
        config.git_dir = "plugins/#{ENV['GITHUB_PROJECT']}"
      end
      CodeClimate::TestReporter::Formatter.new.format(SimpleCov.result)
    end

    task :clear_coverage_data do
      rm_rf coverage_dir
    end
  end
end
