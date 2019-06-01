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

      options = DEFAULTS.merge(options)
      options = process_identikey_filters(options)

      super options
    end

    def self.default_user_agent_header
      {'User-Agent' => "ruby/identikey #{Identikey::VERSION}"}
    end

    # Loops over the filters option content and adds Identikey
    # specific parameter filtering.
    #
    # Due to faulty design in the Identikey SOAP endpoint, the
    # parameter filters require context-dependant logic as all
    # attributes are passed in `<attributeID>` elements, while
    # all values are passed in `<value>` elements.
    #
    # Identikey attributes to filter out are specified in the
    # `filters` option with the `identikey:` prefix.
    #
    # Example, filter out the `CREDFLD_PASSWORD` field from
    # the logs (done by default):
    #
    # configure do
    #   filters [ 'identikey:CREDFLD_PASSWORD' ]
    # end
    #
    def self.process_identikey_filters(options)
      filters = options[:filters] || []

      options[:filters] = filters.map do |filter|
        if filter.to_s =~ /^identikey:(.+)/
          filter = identikey_filter_proc_for($1)
        end

        filter
      end

      return options
    end

    def self.identikey_filter_proc_for(attribute)
      lambda do |document|
        document.xpath("//attributeID[text()='#{attribute}']/../value").each do |node|
          node.content = '***FILTERED***'
        end
      end
    end

    DEFAULTS = {
      endpoint: 'https://localhost:8888/',

      ssl_version: :TLSv1_2,
      ssl_verify_mode: :none,

      headers: default_user_agent_header,

      encoding: 'UTF-8',

      logger: Logger.new('log/identikey.log'),
      log_level: :debug,
      log: true,
      pretty_print_xml: true,

      filters: [
        'identikey:CREDFLD_PASSWORD',
        'identikey:CREDFLD_STATIC_PASSWORD',
        'identikey:CREDFLD_SESSION_ID'
      ]
    }.freeze

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
          raise Identikey::ParseError, "Empty response received"
        end

        unless body.key?(root_element)
          raise Identikey::ParseError, "Expected response to have #{root_element}, found #{body.keys.join(', ')}"
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
          raise Identikey::ParseError, "Results element not found below #{root_element}"
        end

        results = root[:results]

        # Result code
        #
        unless results.key?(:result_codes)
          raise Identikey::ParseError, "Result codes not found below #{root_element}"
        end

        result_code = results[:result_codes][:status_code_enum] || 'STAT_UNKNOWN'

        # Result attributes
        #
        unless results.key?(:result_attribute)
          raise Identikey::ParseError, "Result attribute not found below #{root_element}"
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

      # Converts and hash keyed by attribute name into an array of hashes
      # whose keys are the attribute name as attributeID and the value as
      # a Gyoku-compatible hash with the xsd:type annotation. The type is
      # inferred from the Ruby value type and the contents are serialized
      # as a string formatted as per the XSD DTD definition.
      #
      # <rant>
      # This code should not exist, because defining argument types is what
      # WSDL is for.  However, in the braindead web services implementation
      # of Vasco there are infinite protocols that accept a variable number
      # of attributes and their types are defined only in the documentation
      # and in server code, making WSDL (and SOAP) only an annoynace rather
      # than an aid.
      # </rant>
      #
      def typed_attributes_list_from(hash)
        hash.map do |name, value|
          type, value = case value

          when Unsigned
            [ 'xsd:unsignedInt', value.to_s ]

          when Integer
            [ 'xsd:int', value.to_s ]

          when DateTime, Time
            [ 'xsd:datetime', value.utc.iso8601 ]

          when TrueClass, FalseClass
            [ 'xsd:boolean', value.to_s ]

          when Symbol, String
            [ 'xsd:string', value.to_s ]

          when NilClass
            next

          else
            raise Identikey::UsageError, "#{name} type #{value.class} is unsupported"
          end

          { attributeID: name.to_s,
            value: { '@xsi:type': type, content!: value } }
        end.compact
      end

    # protected

  end

end
