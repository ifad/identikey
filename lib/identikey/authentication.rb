module Identikey
  class Authentication
    extend Savon::Model

    client wsdl: './sdk/wsdl/authentication.wsdl',
      endpoint: 'https://localhost:8888/',
      ssl_version: :TLSv1_2,

      headers: {'User-Agent' => "ruby/identikey #{Identikey::VERSION}"},
      encoding: 'UTF-8',

      logger: Logger.new('log/soap-authentication.log'),
      log_level: :debug,
      pretty_print_xml: true

    def auth_user(user, otp, domain: 'root')
      client.call(:auth_user, message: {
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
    end
  end
end
