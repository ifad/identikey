lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "identikey/version"

Gem::Specification.new do |spec|
  spec.name          = "identikey"
  spec.version       = Identikey::VERSION
  spec.authors       = ["Marcello Barnaba"]
  spec.email         = ["vjt@openssl.it"]

  spec.summary       = %q{OneSpan Authentication Server (former VASCO Identikey) wrapper for Ruby}
  spec.description   = %q{This gem contains a SOAP client to consume Identikey API}
  spec.homepage      = "https://github.com/ifad/identikey"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "savon", "~> 2.0"
  spec.add_dependency "wasabi", "~> 3.5.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'hirb'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'vacman_controller'
  spec.add_development_dependency 'code_counter'
end
