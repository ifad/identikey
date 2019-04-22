module Identikey
  class Administration

    class Session
      attr_reader :username, :password, :domain
      attr_reader :session_id, :product, :version
      attr_reader :privileges

      def initialize(username:, password:, domain: 'master')
        @client = Identikey::Administration.new

        logon(username: username, password: password, domain: domain)
      end

      def logon(username: @username, password: @password, domain: @domain)
        stat, resp = @client.logon(username: username, password: password, domain: domain)

        if stat != 'STAT_SUCCESS'
          raise Identikey::Error, "logon failed: #{stat}"
        end

        @privileges = parse_privileges resp['CREDFLD_LOGICAL_ADMIN_PRIVILEGES']

        @session_id = resp['CREDFLD_SESSION_ID']
        @username   = resp['CREDFLD_USERID']
        @password   = resp['CREDFLD_STATIC_PASSWORD']
        @domain     = resp['CREDFLD_DOMAIN']

        @product    = resp['CREDFLD_PRODUCT_NAME']
        @version    = resp['CREDFLD_PRODUCT_VERSION']
        @last_logon = resp['CREDFLD_LAST_LOGON_TIME']

        self
      end

      def logoff
        if @session_id.nil?
          raise Identikey::Error, "Session is not logged on at the moment"
        end

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

      def inspect
        "#<#{self.class.name} sid=#@session_id username=#@username domain=#@domain product=#@product>"
      end

      alias sid session_id

      def logged_on?
        !@session_id.nil?
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
