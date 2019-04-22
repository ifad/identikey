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

    operations :logon, :logoff

    def logon(username:, password:, domain: 'master')
      resp = super(message: {
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

      parse_response resp, :logon_response
    end

    def logoff(session_id:)
      resp = super(message: {
        attributeSet: {
          attributes: [
            { attributeID: 'CREDFLD_SESSION_ID',
              value: { :'@xsi:type' => 'xsd:string', :content! => sid.to_s }
            }
          ]
        }
      })

      parse_response resp, :logoff_response
    end

    def parse_response(resp, root_element)
      body = resp.body

      if body.size.zero?
        raise Identikey::Error, "Empty response received"
      end

      unless body.key?(root_element)
        raise Identikey::Error, "Expected response to have #{root_element}, found #{body.keys.join(', ')}"
      end

      unless body[root_element].key?(:results)
        raise Identikey::Error, "Results element not found below #{root_element}"
      end

      results = body[root_element][:results]

      unless results.key?(:result_codes)
        raise Identikey::Error, "Result codes not found below #{root_element}"
      end

      result_code = results[:result_codes][:status_code_enum] || 'STAT_UNKNOWN'

      unless results.key?(:result_attribute)
        raise Identikey::Error, "Result attribute not found below #{root_element}"
      end

      result_attributes = if (attrs = results[:result_attribute].key?(:attributes))
        results[:result_attribute][:attributes].inject({}) do |h, attribute|
          h.update(attribute.fetch(:attribute_id) => attribute.fetch(:value))
        end
      else
        {}
      end

      return result_code, result_attributes
    end
  end
end
