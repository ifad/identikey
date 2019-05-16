require 'identikey/base'

module Identikey
  class Authentication < Base
    client wsdl: './sdk/wsdl/authentication.wsdl'

    operations :auth_user

    def auth_user(user, domain, otp)
      resp = super(message: {
        credentialAttributeSet: {
          attributes: [
            { attributeID: 'CREDFLD_COMPONENT_TYPE',
              value: {
                :'@xsi:type' => 'xsd:string',
                :content!    => 'Administration Program'
              }
            },

            { attributeID: 'CREDFLD_USERID',
              value: { :'@xsi:type' => 'xsd:string', :content! => user.to_s }
            },

            { attributeID: 'CREDFLD_DOMAIN',
              value: { :'@xsi:type' => 'xsd:string', :content! => domain.to_s }
            },

            { attributeID: 'CREDFLD_PASSWORD_FORMAT',
              value: { :'@xsi:type' => 'xsd:unsignedInt', :content! => 0 }
            },

            { attributeID: 'CREDFLD_PASSWORD',
              value: { :'@xsi:type' => 'xsd:string', :content! => otp.to_s }
            },
          ]
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
