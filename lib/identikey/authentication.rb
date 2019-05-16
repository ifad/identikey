require 'identikey/base'

module Identikey
  class Authentication < Base
    client wsdl: './sdk/wsdl/authentication.wsdl'

    operations :auth_user

    def auth_user(user, domain, otp)
      resp = super(message: {
        credentialAttributeSet: {
          attributes: typed_attributes_list_from(
            CREDFLD_COMPONENT_TYPE: 'Administration Program',
            CREDFLD_USERID: user,
            CREDFLD_DOMAIN: domain,
            CREDFLD_PASSWORD_FORMAT: Unsigned(0),
            CREDFLD_PASSWORD: otp
          )
        }
      })

      parse_response resp, :auth_user_response
    end

    def self.valid_otp?(user, domain, otp)
      status, _ = new.auth_user(user, domain, otp)
      return status == 'STAT_SUCCESS'
    end

    def self.validate!(user, domain, otp)
      status, result, _ = new.auth_user(user, domain, otp)
      if status == 'STAT_SUCCESS'
        return true
      else
        error_message = result['CREDFLD_STATUS_MESSAGE']
        raise Identikey::Error, "OTP Validation error (#{status}): #{error_message}"
      end
    end
  end
end
