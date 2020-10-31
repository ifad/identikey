require 'identikey/base'

module Identikey
  # This class wraps the Provisioning API.
  #
  class Provisioning < Base
    client wsdl: './sdk/wsdl/provisioning.wsdl'

    operations :provisioning_execute, :dsapp_srp_register

    ###
    ## PROVISIONING_EXECUTE
    ###

    def provisioning_execute(cmd:, attributes:)
      resp = super(message: {
        cmd: cmd,
        attributeSet: {
          attributes: attributes
        }
      })

      parse_response resp, :provisioning_execute_response
    end

    def provisioning_execute_MDL_REGISTER(component:, user:, domain:, password:)
      provisioning_execute(
        cmd: 'PROVISIONCMD_MDL_REGISTER',
        attributes: typed_attributes_list_from(
          PROVFLD_USERID:          user,
          PROVFLD_DOMAIN:          domain,
          PROVFLD_COMPONENT_TYPE:  component,
          PROVFLD_STATIC_PASSWORD: password,
          PROVFLD_ACTIVATION_TYPE: Unsigned(0),
        )
      )
    end

    ###
    ## dsappSRPRegister
    ###

    def dsapp_srp_register(component:, user:, domain:, password:)
      resp = super(message: {
        componentType: component,
        user: {
          userID: user,
          domain: domain,
        },
        credential: {
          staticPassword: password
        }
      })

      parse_response resp, :dsapp_srp_register_response
    end

    ###
    ## Wraps dsapp_srp_register and returns directly the activation
    ## message through which a CRONTO image can be generated, to be
    ## used for push notifications setups in combination with a MDC
    ## configured on your OneSpan control panel and on Identikey.
    ####
    def dsapp_srp_cronto_push(gateway:, **kwargs)
      status, result, error = self.dsapp_srp_register(**kwargs)

      if status != 'STAT_SUCCESS'
        raise Identikey::OperationFailed, "Error while assigning DAL: #{status} - #{[error].flatten.join('; ')}"
      end

      # Compose proprietary string
      message = '01;01;%s;%s;%s;%s;%s' % [
        result[:user][:user_id],
        result[:user][:domain],
        result[:registration_id],
        result[:activation_password],
        gateway
      ]

      # Encode it as hex
      return message.split(//).map {|c| '%x' % c.ord}.join
    end

    protected
      # The provisioningExecute command has the same
      # design as the rest of the API, with a single
      # multi-purpose `results` element that carries
      # key-value results.
      #
      # Instead, dsappSRPRegister and other commands
      # use a different design with return types and
      # values predefined in the WSDL.
      #
      # So if we have a `results` element, this is a
      # old-style response, and we delegate parsing
      # to the parent class, otherwise if we detect
      # the `result` and `status` elements, we parse
      # in this class, basically just returning the
      # values that Savon parsed for us.
      #
      def parse_result_element(root, root_element)
        if root.key?(:results)
          root[:results]
        else
          root
        end
      end

      def parse_result_code(root, root_element)
        if root.key?(:status)
          super root[:status], root_element
        else
          super
        end
      end

      # This may be an old or a new style response.
      #
      # New style responses may have both `result`
      # and `status` elements, or only a `status`
      # element.
      #
      # If there is no `result` but there is a
      # `status`, then consider this a new style
      # response and return an empty result. Else,
      # pass along to the superclass to parse the
      # old style response.
      #
      def parse_result_attributes(root, root_element)
        if root.key?(:result)
          root[:result]
        elsif root.key?(:status)
          nil
        else
          super
        end
      end

      def parse_result_errors(root, root_element)
        if root.key?(:status)
          super root[:status], root_element
        else
          super
        end
      end
  end
end
