module Identikey
  class Administration
    extend Savon::Model

    client wsdl: './sdk/wsdl/administration.wsdl',
      endpoint: 'https://localhost:8888/',
      ssl_version: :TLSv1_2,

      headers: {'User-Agent' => "ruby/identikey #{Identikey::VERSION}"},
      encoding: 'UTF-8',

      logger: Logger.new('log/soap-administration.log'),
      log_level: :debug,
      pretty_print_xml: true

    def logon(username, password, domain: 'master')
      client.call(:logon, message: {
        attributeSet: {
          attributes: [
            { attributeID: 'CREDFLD_DOMAIN',
              value: { :'@xsi:type' => 'xsd:string', :content! => domain.to_s }
            },

            { attributeID: 'CREDFLD_PASSWORD',
              value: { :'@xsi:type' => 'xsd:string', :content! => password.to_s }
            },

            { attributeID: 'CREDFLD_USERID',
              value: { :'@xsi:type' => 'xsd:string', :content! => username.to_s }
            },

            { attributeID: 'CREDFLD_PASSWORD_FORMAT',
              value: { :'@xsi:type' => 'xsd:unsignedInt', :content! => 0
              }
            }
          ]
        }
      })
    end

    def logoff(sid)
      client.call(:logoff, message: {
        attributeSet: {
          attributes: [
            { attributeID: 'CREDFLD_SESSION_ID',
              value: { :'@xsi:type' => 'xsd:string', :content! => sid.to_s }
            }
          ]
        }
      })
    end

  end
end
