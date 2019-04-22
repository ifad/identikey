require 'identikey/administration/session'

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

    operations :logon, :logoff, :sessionalive, :admin_session_query

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
              value: { :'@xsi:type' => 'xsd:string', :content! => session_id.to_s }
            }
          ]
        }
      })

      parse_response resp, :logoff_response
    end

    def sessionalive(session_id:)
      resp = super(message: {
        attributeSet: {
          attributes: [
            { attributeID: 'CREDFLD_SESSION_ID',
              value: { :'@xsi:type' => 'xsd:string', :content! => session_id.to_s }
            }
          ]
        }
      })

      parse_response resp, :sessionalive_response
    end

    def admin_session_query(session_id:)
      attributes = [ ]

      # These doesn't seem to work as described by the WSDL.
      # if q_idx
      #   attributes.push(attributeID: 'ADMINSESSIONFLD_SESSION_IDX',
      #                   value: { '@xsi:type': 'xsd:string', content!: q_idx})
      # end

      # if q_location
      #   attributes.push(attributeID: 'ADMINSESSIONFLD_LOCATION',
      #                   value: { '@xsi:type': 'xsd:string', content!: q_location})
      # end

      # if q_username
      #   attributes.push(attributeID: 'ADMINSESSIONFLD_LOGIN_NAME',
      #                   value: { '@xsi:type': 'xsd:string', content!: q_username})
      # end

      resp = super(message: {
        sessionID: session_id,
        attributeSet: {
          attributes: attributes
        }
        # fieldSet: { ... }
        # queryOptions: { ... }
      })

      parse_response resp, :admin_session_query_response
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

      results_attr = results[:result_attribute]

      result_attributes = if results_attr.key?(:attributes)
        parse_attributes results_attr[:attributes]

      elsif results_attr.key?(:attribute_list)
        results_attr[:attribute_list].inject([]) do |a, entry|
          a.push parse_attributes(entry[:attributes])
        end
      else
        nil
      end

      errors = if results[:error_stack].key?(:errors)
        parse_errors results[:error_stack][:errors]
      else
        nil
      end

      return result_code, result_attributes, errors
    end

    def parse_attributes(attributes)
      attributes.inject({}) do |h, attribute|
        h.update(attribute.fetch(:attribute_id) => attribute.fetch(:value))
      end
    end

    def parse_errors(errors)
      case errors
      when Array
        errors.map { |e| e.fetch(:error_desc) }
      when Hash
        errors.fetch(:error_desc)
      end
    end
  end
end
