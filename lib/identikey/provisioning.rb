require 'identikey/base'

module Identikey
  # This class wraps the Provisioning API.
  #
  class Provisioning < Base
    client wsdl: './sdk/wsdl/provisioning.wsdl'

    operations :dsapp_srp_register

    ###
    ## PROVISIONING_EXECUTE
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

  end
end
