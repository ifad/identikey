require 'identikey/base'
require 'identikey/administration/session'
require 'identikey/administration/session_query'
require 'identikey/administration/digipass'

module Identikey
  # This class wraps the Administration API wsdl, that contains dozens of
  # methods. It is currently monolithic.
  #
  # It's the lower level into the Administration API, while its models are
  # wrapped in separate clasess.
  #
  class Administration < Base
    client wsdl: './sdk/wsdl/administration.wsdl'

    operations :logon, :logoff, :sessionalive,
      :admin_session_query, :digipass_execute, :digipassappl_execute

    def logon(username:, password:, domain: 'master')
      resp = super(message: {
        attributeSet: {
          attributes: [
            { attributeID: 'CREDFLD_DOMAIN',
              value: { '@xsi:type': 'xsd:string', content!: domain.to_s }
            },

            { attributeID: 'CREDFLD_PASSWORD',
              value: { '@xsi:type': 'xsd:string', content!: password.to_s }
            },

            { attributeID: 'CREDFLD_USERID',
              value: { '@xsi:type': 'xsd:string', content!: username.to_s }
            },

            { attributeID: 'CREDFLD_PASSWORD_FORMAT',
              value: { '@xsi:type': 'xsd:unsignedInt', content!: 0
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
              value: { '@xsi:type': 'xsd:string', content!: session_id.to_s }
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
              value: { '@xsi:type': 'xsd:string', content!: session_id.to_s }
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

    def digipass_execute_UNASSIGN(session_id:, serial_no:)
      digipass_execute(
        session_id: session_id,
        cmd: 'DIGIPASSCMD_UNASSIGN',
        attributes: [
          { attributeID: 'DIGIPASSFLD_SERNO',
            value: { '@xsi:type': 'xsd:string', content!: serial_no } }
        ]
      )
    end

    def digipass_execute_ASSIGN(session_id:, serial_no:, username:, domain: 'root', grace_period: 0)
      digipass_execute(
        session_id: session_id,
        cmd: 'DIGIPASSCMD_ASSIGN',
        attributes: [
          { attributeID: 'DIGIPASSFLD_SERNO',
            value: { '@xsi:type': 'xsd:string', content!: serial_no } },
          { attributeID: 'DIGIPASSFLD_ASSIGNED_USERID',
            value: { '@xsi:type': 'xsd:string', content!: username } },
          { attributeID: 'DIGIPASSFLD_DOMAIN',
            value: { '@xsi:type': 'xsd:string', content!: domain } },
          { attributeID: 'DIGIPASSFLD_GRACE_PERIOD_DAYS',
            value: { '@xsi:type': 'xsd:int', content!: grace_period } }
        ]
      )
    end

    def digipassappl_execute(session_id:, cmd:, attributes:)
      resp = super(message: {
        sessionID: session_id,
        cmd: cmd,
        attributeSet: {
          attributes: attributes
        }
      })

      parse_response resp, :digipassappl_execute_response
    end

    def digipassappl_execute_TEST_OTP(session_id:, serial_no:, appl:, otp:)
      digipassappl_execute(
        session_id: session_id,
        cmd: 'DIGIPASSAPPLCMD_TEST_OTP',
        attributes: [
          { attributeID: 'DIGIPASSAPPLFLD_SERNO',
            value: { '@xsi:type': 'xsd:string', content!: serial_no } },
          { attributeID: 'DIGIPASSAPPLFLD_APPL_NAME',
            value: { '@xsi:type': 'xsd:string', content!: appl } },
          { attributeID: 'DIGIPASSAPPLFLD_RESPONSE',
            value: { '@xsi:type': 'xsd:string', content!: otp } }
        ]
      )
    end

  end
end
