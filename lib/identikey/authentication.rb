require 'identikey/base'

module Identikey
  class Authentication < Base
    client wsdl: './sdk/wsdl/authentication.wsdl'

    operations :auth_user

    def auth_user(user, domain, otp, client = nil)
      client ||= 'Administration Program'

      resp = super(message: {
        credentialAttributeSet: {
          attributes: typed_attributes_list_from(
            CREDFLD_COMPONENT_TYPE: client,
            CREDFLD_USERID: user,
            CREDFLD_DOMAIN: domain,
            CREDFLD_PASSWORD_FORMAT: Unsigned(0),
            CREDFLD_PASSWORD: otp
          )
        }
      })

      parse_response resp, :auth_user_response
    end

    def self.valid_otp?(user, domain, otp, client = nil)
      status, result, _ = new.auth_user(user, domain, otp, client)
      return otp_validated_ok?(status, result)
    end

    def self.validate!(user, domain, otp, client = nil)
      status, result, error_stack = new.auth_user(user, domain, otp, client)

      if otp_validated_ok?(status, result)
        return true
      else
        error_message = result['CREDFLD_STATUS_MESSAGE']
        raise Identikey::OperationFailed.new("OTP Validation error (#{status}): #{error_message}", error_stack)
      end
    end

    # Given an authentication status and result message, returns true if
    # that defines a successful OTP validation or not.
    #
    # For all cases, except where the OTP is "push", Identikey returns a
    # status that is != than `STAT_SUCCESS`. But when the OTP is "push",
    # then Identikey returns a `STAT_SUCCESS` with a "password is wrong"
    # message in the `CREDFLD_STATUS_MESSAGE`.
    #
    # This method checks for both cases.. Success means a `STAT_SUCCESS`
    # and nothing in the `CREDFLD_STATUS_MESSAGE`.
    #
    def self.otp_validated_ok?(status, result)
      status == 'STAT_SUCCESS' && !result.key?('CREDFLD_STATUS_MESSAGE')
    end
  end
end
