module Identikey
  class Administration < Base

    class Session
      attr_reader :username, :password, :domain
      attr_reader :session_id, :product, :version
      attr_reader :privileges, :location

      def initialize(username:, password:, domain: 'master')
        @client = Identikey::Administration.new

        @username = username
        @password = password
        @domain   = domain
      end

      def endpoint
        @client.endpoint
      end

      def wsdl
        @client.wsdl
      end

      def logon
        stat, sess, error = @client.logon(username: @username, password: @password, domain: @domain)

        if stat != 'STAT_SUCCESS'
          raise Identikey::LogonFailed, "logon failed: #{stat} - #{error}"
        end

        @privileges = parse_privileges sess['CREDFLD_LOGICAL_ADMIN_PRIVILEGES']

        @session_id = sess['CREDFLD_SESSION_ID'].freeze
        @location   = sess['CREDFLD_USER_LOCATION'].freeze
        @last_logon = sess['CREDFLD_LAST_LOGON_TIME'].freeze

        @product    = sess['CREDFLD_PRODUCT_NAME'].freeze
        @version    = sess['CREDFLD_PRODUCT_VERSION'].freeze

        self
      end

      def logoff
        require_logged_on!

        stat, _, error = @client.logoff session_id: @session_id

        unless stat == 'STAT_ADMIN_SESSION_STOPPED' || stat == 'STAT_SUCCESS'
          raise Identikey::LogonFailed, "logoff failed: #{stat} - #{error}"
        end

        @privileges = nil
        @session_id = nil
        @product    = nil
        @version    = nil
        @last_logon = nil

        stat == 'STAT_SUCCESS'
      end

      def alive?(log: true)
        return false unless logged_on?

        stat, _ = @client.ping session_id: @session_id, log: log

        stat == 'STAT_SUCCESS'
      end

      def execute(command, *args)
        kwargs = args.first || {}
        kwargs.update(session_id: @session_id)
        @client.public_send(command, kwargs)
      end

      def all
        require_logged_on!

        SessionQuery.all session: self
      end

      def find_digipass(serial_no)
        require_logged_on!

        Digipass.find session: self, serial_no: serial_no
      end

      def find_user(username, domain = nil)
        require_logged_on!

        User.find session: self, username: username, domain: domain || self.domain
      end

      def inspect
        "#<#{self.class.name} sid=#@session_id username=#@username domain=#@domain product=#@product>"
      end

      alias sid session_id

      def logged_on?
        !@session_id.nil?
      end

      def require_logged_on!
        unless logged_on?
          raise Identikey::UsageError, "Session is not logged on at the moment"
        end
      end

      def parse_privileges(privileges)
        privileges.split(', ').inject({}) do |h, priv|
          privilege, status = priv.split(' ')
          h.update(privilege => status == 'true')
        end.freeze
      end
    end

  end
end
