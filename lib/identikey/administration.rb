require 'identikey/base'
require 'identikey/administration/session'
require 'identikey/administration/session_query'
require 'identikey/administration/digipass'
require 'identikey/administration/user'

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
      :admin_session_query, :user_execute, :user_query,
      :digipass_execute, :digipass_query, :digipassappl_execute

    ###
    ## LOGON/LOGOFF/PING
    ###

    def logon(username:, password:, domain:)
      resp = super(message: {
        attributeSet: {
          attributes: typed_attributes_list_from(
            CREDFLD_DOMAIN:          domain,
            CREDFLD_PASSWORD:        password,
            CREDFLD_USERID:          username,
            CREDFLD_PASSWORD_FORMAT: Unsigned(0)
          )
        }
      })

      parse_response resp, :logon_response
    end

    def logoff(session_id:)
      resp = super(message: {
        attributeSet: {
          attributes: typed_attributes_list_from(
            CREDFLD_SESSION_ID: session_id
          )
        }
      })

      parse_response resp, :logoff_response
    end

    def sessionalive(session_id:)
      resp = super(message: {
        attributeSet: {
          attributes: typed_attributes_list_from(
            CREDFLD_SESSION_ID: session_id
          )
        }
      })

      parse_response resp, :sessionalive_response
    end

    # Like sessionalive, but allows to disable logging if the
    # `log:` keyword is set to false.
    #
    def ping(session_id:, log:)
      logging_to(log) { sessionalive(session_id: session_id) }
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

    ###
    ## USER_EXECUTE
    ###

    def user_execute(session_id:, cmd:, attributes: [])
      resp = super(message: {
        sessionID: session_id,
        cmd: cmd,
        attributeSet: {
          attributes: attributes
        }
      })

      parse_response resp, :user_execute_response
    end

    def user_execute_VIEW(session_id:, username:, domain:)
      user_execute(
        session_id: session_id,
        cmd: 'USERCMD_VIEW',
        attributes: typed_attributes_list_from(
          USERFLD_USERID: username,
          USERFLD_DOMAIN: domain
        )
      )
    end

    def user_execute_CREATE(session_id:, attributes:)
      user_execute(
        session_id: session_id,
        cmd: 'USERCMD_CREATE',
        attributes: typed_attributes_list_from(attributes)
      )
    end

    def user_execute_UPDATE(session_id:, attributes:)
      user_execute(
        session_id: session_id,
        cmd: 'USERCMD_UPDATE',
        attributes: typed_attributes_list_from(attributes)
      )
    end

    def user_execute_DELETE(session_id:, username:, domain:)
      user_execute(
        session_id: session_id,
        cmd: 'USERCMD_DELETE',
        attributes: typed_attributes_list_from(
          USERFLD_USERID: username,
          USERFLD_DOMAIN: domain
        )
      )
    end

    def user_execute_RESET_PASSWORD(session_id:, username:, domain:)
      user_execute(
        session_id: session_id,
        cmd: 'USERCMD_RESET_PASSWORD',
        attributes: typed_attributes_list_from(
          USERFLD_USERID: username,
          USERFLD_DOMAIN: domain
        )
      )
    end

    def user_execute_SET_PASSWORD(session_id:, username:, domain:, password:)
      user_execute(
        session_id: session_id,
        cmd: 'USERCMD_SET_PASSWORD',
        attributes: typed_attributes_list_from(
          USERFLD_USERID: username,
          USERFLD_DOMAIN: domain,
          USERFLD_NEW_PASSWORD: password,
          USERFLD_CONFIRM_NEW_PASSWORD: password
        )
      )
    end

    def user_execute_UNLOCK(session_id:, username:, domain:)
      user_execute(
        session_id: session_id,
        cmd: 'USERCMD_UNLOCK',
        attributes: typed_attributes_list_from(
          USERFLD_USERID: username,
          USERFLD_DOMAIN: domain
        )
      )
    end

    ###
    ## USER_QUERY
    ###

    # Executes a userQuery command that searches users. By default, it doesn't
    # log anywhere. To enable logging to a specific destination, pass a logger
    # as the log: option. To log to the default destination, pass `true` as
    # the log: option.
    #
    def user_query(session_id:, attributes:, query_options:, log: false)
      logging_to(log) do
        resp = super(message: {
          sessionID: session_id,
          attributeSet: {
            attributes: typed_attributes_query_list_from(attributes)
          },
          queryOptions: query_options
        })

        parse_response resp, :user_query_response
      end
    end

    ###
    ## DIGIPASS_EXECUTE
    ###

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
        attributes: typed_attributes_list_from(
          DIGIPASSFLD_SERNO: serial_no
        )
      )
    end

    def digipass_execute_UNASSIGN(session_id:, serial_no:)
      digipass_execute(
        session_id: session_id,
        cmd: 'DIGIPASSCMD_UNASSIGN',
        attributes: typed_attributes_list_from(
          DIGIPASSFLD_SERNO: serial_no
        )
      )
    end

    def digipass_execute_ASSIGN(session_id:, serial_no:, username:, domain:, grace_period: 0, expires_at: nil)
      digipass_execute(
        session_id: session_id,
        cmd: 'DIGIPASSCMD_ASSIGN',
        attributes: typed_attributes_list_from(
          DIGIPASSFLD_SERNO: serial_no,
          DIGIPASSFLD_ASSIGNED_USERID: username,
          DIGIPASSFLD_DOMAIN: domain,
          DIGIPASSFLD_GRACE_PERIOD_DAYS: grace_period,
          DIGIPASSFLD_EXPIRATION_TIME: expires_at

        )
      )
    end

    ###
    ## DIGIPASS_QUERY
    ###

    def digipass_query(session_id:, attributes:, query_options:)
      resp = super(message: {
        sessionID: session_id,
        attributeSet: {
          attributes: typed_attributes_query_list_from(attributes)
        },
        queryOptions: query_options
      })

      parse_response resp, :digipass_query_response
    end

    ###
    ## DIGIPASSAPPL_EXECUTE
    ###

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
        attributes: typed_attributes_list_from(
          DIGIPASSAPPLFLD_SERNO: serial_no,
          DIGIPASSAPPLFLD_APPL_NAME: appl,
          DIGIPASSAPPLFLD_RESPONSE: otp
        )
      )
    end

    def digipassappl_execute_SET_PIN(session_id:, serial_no:, appl:, pin:)
      digipassappl_execute(
        session_id: session_id,
        cmd: 'DIGIPASSAPPLCMD_SET_PIN',
        attributes: typed_attributes_list_from(
          DIGIPASSAPPLFLD_SERNO: serial_no,
          DIGIPASSAPPLFLD_APPL_NAME: appl,
          DIGIPASSAPPLFLD_NEW_PIN: pin,
          DIGIPASSAPPLFLD_NEW_PIN_CONF: pin
        )
      )
    end

    private
      # Allows temporarily overriding the log destination. If it
      # is set to `false` then logging is disabled altogether.
      # If it is set to `true`, then this is a no-op.
      #
      def logging_to(destination)
        old_log = client.globals[:log]

        unless destination === true
          client.globals[:log] = destination
        end

        yield

      ensure
        client.globals[:log] = old_log
      end

  end
end
