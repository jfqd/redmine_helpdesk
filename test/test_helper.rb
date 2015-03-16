require "simplecov"
require "codeclimate-test-reporter"

SimpleCov.use_merging true
SimpleCov.merge_timeout 3600
SimpleCov.add_filter '/test/'
SimpleCov.add_filter 'init.rb'
SimpleCov.formatters = []
SimpleCov.start(CodeClimate::TestReporter.configuration.profile) do
  root File.expand_path(File.dirname(__FILE__) + '/../../')
end

# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

class ActiveSupport::TestCase
      self.fixture_path = File.dirname(__FILE__) + '/fixtures'
end
