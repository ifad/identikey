require 'bundler/setup'

require 'simplecov'
SimpleCov.start do
  add_filter '.bundle'
end

require 'byebug'

require 'dotenv'
# Load environment variables.
Dotenv.load 'spec/test.env'

require 'identikey'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = "spec/examples.txt"

  config.profile_examples = 5

  config.before :suite do
    Identikey::Authentication.configure do
      wsdl     ENV['IK_WSDL_AUTH'] if ENV['IK_WSDL_AUTH']
      endpoint ENV['IK_HOST']      if ENV['IK_HOST']
    end

    Identikey::Administration.configure do
      wsdl     ENV['IK_WSDL_ADMIN'] if ENV['IK_WSDL_ADMIN']
      endpoint ENV['IK_HOST']       if ENV['IK_HOST']
    end
  end
end
