require 'bundler/setup'

require 'simplecov'
SimpleCov.start do
  add_filter '.bundle'
end

require 'byebug'

require 'identikey'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before :suite do
    Identikey::Authentication.configure do
      wsdl     ENV['WSDL_AUTH'] if ENV['WSDL_AUTH']
      endpoint ENV['TEST_HOST'] if ENV['TEST_HOST']
    end

    Identikey::Administration.configure do
      wsdl     ENV['WSDL_ADMIN'] if ENV['WSDL_ADMIN']
      endpoint ENV['TEST_HOST']  if ENV['TEST_HOST']
    end
  end
end
