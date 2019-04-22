require 'identikey/administration/session'
require 'identikey/administration/session_query'

module Identikey
  # This class wraps the Administration API wsdl, that contains dozens of
  # methods. It is currently monolithic.
  #
  # It's the lower level into the Administration API, while its models are
  # wrapped in separate clasess.
  #
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

    operations :logon, :logoff, :sessionalive, :admin_session_query, :digipass_execute

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

    def digipass_execute(session_id:, cmd:, attributes: [])
      resp = super(message: {
        sessionID: session_id,
        cmd: cmd,
        attributeSet: {
          attributes: attributes
        }
      })

      parse_response resp, :digipass_execute_response
    end

    def digipass_execute_VIEW(session_id:, serial_no:)
      digipass_execute(
        session_id: session_id,
        cmd: 'DIGIPASSCMD_VIEW',
        attributes: [
          { attributeID: 'DIGIPASSFLD_SERNO',
            value: { '@xsi:type': 'xsd:string', content!: serial_no } }
        ]
      )
    end

    # Parse the generic response types that the API returns.
    #
    # The returned attributes (up to now...) are always:
    #
    # - The given root element, whose name is derived from the SOAP command
    #   that was invoked
    # - The :results element, containing:
    #   - :result_codes, containing :status_code_enum that is the operation
    #     result code
    #   - :result_attribute, that may either contain a single attributes list
    #      or multiple ones.
    #   - :error_stack, a list of error that occurred
    #
    # The returned value is a three-elements array, containing:
    #
    #   [Response code, Attribute(s) list, Errors list]
    #
    # The response code is a string from the IDENTIKEY Authentication Server
    # Error Codes table.
    #
    # The attributes list is an Hash when a single object's attributes were
    # requested, or is an Array of Hashes when the response contains a list
    # of objects.
    #
    # The attributes list may be nil.
    #
    # The errors list is an array of strings containing error descriptions.
    # The strings themselves contain the error code, albeit in different
    # formats. TODO maybe create a separate class for errors, that includes
    # the error code.
    #
    # TODO refactor and split in separate methods
    #
    def parse_response(resp, root_element)
      body = resp.body

      if body.size.zero?
        raise Identikey::Error, "Empty response received"
      end

      unless body.key?(root_element)
        raise Identikey::Error, "Expected response to have #{root_element}, found #{body.keys.join(', ')}"
      end

      # The results element
      #
      unless body[root_element].key?(:results)
        raise Identikey::Error, "Results element not found below #{root_element}"
      end

      results = body[root_element][:results]

      # Result code
      #
      unless results.key?(:result_codes)
        raise Identikey::Error, "Result codes not found below #{root_element}"
      end

      result_code = results[:result_codes][:status_code_enum] || 'STAT_UNKNOWN'

      # Result attributes
      #
      unless results.key?(:result_attribute)
        raise Identikey::Error, "Result attribute not found below #{root_element}"
      end

      results_attr = results[:result_attribute]

      result_attributes = if results_attr.key?(:attributes)
        parse_attributes results_attr[:attributes]

      elsif results_attr.key?(:attribute_list)
        # This attribute may contain a single entry or multiple ones. Lists of
        # a single element are returned as a single attributes set.. but the
        # caller expects a list so we return the single element in an Array.
        #
        entries = [ results_attr[:attribute_list] ].flatten
        entries.inject([]) do |a, entry|
          a.push parse_attributes(entry[:attributes])
        end
      else
        nil
      end

      # Errors
      #
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
