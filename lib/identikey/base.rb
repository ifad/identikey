module Identikey

  class Base
    extend Savon::Model

    def self.configure(&block)
      self.client.globals.instance_eval(&block)

      # Work around a sillyness in Savon
      if client.globals[:wsdl] != client.wsdl.document
        client.wsdl.document = client.globals[:wsdl]
      end
    end

    def self.client(options = nil)
      return super() unless options

      defaults = {
        endpoint: 'https://localhost:8888/',

        ssl_version: :TLSv1_2,
        ssl_verify_mode: :none,

        headers: default_user_agent_header,

        encoding: 'UTF-8',

        logger: Logger.new('log/soap.log'),
        log_level: :debug,
        pretty_print_xml: true
      }

      super defaults.merge(options)
    end

    def self.default_user_agent_header
      {'User-Agent' => "ruby/identikey #{Identikey::VERSION}"}
    end

    def endpoint
      self.class.client.globals[:endpoint]
    end

    def wsdl
      self.class.client.globals[:wsdl]
    end

    protected

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

        # The root results element
        #
        root = body[root_element]

        # ... that the authentication API wraps with another element
        #
        results_key = root_element.to_s.sub(/_response$/, '_results').to_sym
        if root.keys.size == 1 && root.key?(results_key)
          root = root[results_key]
        end

        # The results element
        #
        unless root.key?(:results)
          raise Identikey::Error, "Results element not found below #{root_element}"
        end

        results = root[:results]

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
          entries = [ results_attr[:attributes] ].flatten
          parse_attributes entries

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
    # protected

  end

end
