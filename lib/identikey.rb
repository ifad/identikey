require 'savon'

require 'identikey/version'
require 'identikey/unsigned'
require 'identikey/authentication'
require 'identikey/administration'

module Identikey
  # Generic error class
  class Error < StandardError; end

  # Raised when the user is not doing things correctly
  class UsageError < Error; end

  # Raised when the received XML does not conform to documentation
  class ParseError < Error; end

  # Raised when something is "not found", such as an user or a digipass.
  class NotFound < Error; end

  # Raised when Admin logon failed
  class LogonFailed < Error; end

  # Raised when read/write operations fail
  class OperationFailed < Error; end
end
