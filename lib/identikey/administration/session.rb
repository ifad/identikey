module Identikey
  class Administration

    class Session
      attr_reader :username, :password, :domain
      attr_reader :session_id, :product, :version
      attr_reader :privileges, :location

      def initialize(username:, password:, domain: 'master')
        @client = Identikey::Administration.new

        @username = username
        @password = password
        @domain   = domain

        logon
      end

      def logon
        stat, sess, error = @client.logon(username: @username, password: @password, domain: @domain)

        if stat != 'STAT_SUCCESS'
          raise Identikey::Error, "logon failed: #{stat} - #{error}"
        end

        @privileges = parse_privileges sess['CREDFLD_LOGICAL_ADMIN_PRIVILEGES']

        @session_id = sess['CREDFLD_SESSION_ID']
        @location   = sess['CREDFLD_USER_LOCATION']
        @last_logon = sess['CREDFLD_LAST_LOGON_TIME']

        @product    = sess['CREDFLD_PRODUCT_NAME']
        @version    = sess['CREDFLD_PRODUCT_VERSION']

        self
      end

      def logoff
        require_logged_on!

        stat, _ = @client.logoff session_id: @session_id

        unless stat == 'STAT_ADMIN_SESSION_STOPPED'
          raise Identikey::Error, "logoff failed: #{stat}"
        end

        @privileges = nil
        @session_id = nil
        @product    = nil
        @version    = nil
        @last_logon = nil

        stat
      end

      def alive?
        require_logged_on!

        stat, _ = @client.sessionalive session_id: @session_id

        stat == 'STAT_SUCCESS'
      end

      def all
        require_logged_on!

        SessionQuery.all session_id: @session_id
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
          raise Identikey::Error, "Session is not logged on at the moment"
        end
      end

      def parse_privileges(privileges)
        privileges.split(', ').inject({}) do |h, priv|
          privilege, status = priv.split(' ')
          h.update(privilege => status == 'true')
        end
      end
    end

  end
end
