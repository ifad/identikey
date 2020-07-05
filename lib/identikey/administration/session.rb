module Identikey
  class Administration < Base

    class Session
      attr_reader :username, :password, :domain
      attr_reader :session_id, :product, :version
      attr_reader :privileges, :location

      def initialize(username:, password: nil, apikey: nil, domain: 'master')
        if password.nil? && apikey.nil?
          raise Identikey::UsageError, "Either a password or an API Key is required"
        end

        @client = Identikey::Administration.new

        @username = username
        @password = password
        @domain   = domain

        if apikey
          @service_user = true
          @session_id = "Apikey #{username}:#{apikey}"
        end
      end

      def endpoint
        @client.endpoint
      end

      def wsdl
        @client.wsdl
      end

      def logon
        require_classic_user!

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
        require_classic_user!
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
        require_classic_user!

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

      def search_digipasses(query)
        require_logged_on!

        options = query.delete(:options) || {}

        Digipass.search session: self, query: query, options: options
      end

      def find_user(username, domain = nil)
        require_logged_on!

        User.find session: self, username: username, domain: domain || self.domain
      end

      def search_users(query)
        require_logged_on!

        options = query.delete(:options) || {}

        User.search session: self, query: query, options: options
      end

      def inspect
        descr = if service_user?
          "SERVICE USER"
        else
          "domain=#@domain product=#@product"
        end

        "#<#{self.class.name} sid=#@session_id username=#@username #{descr}>"
      end

      def service_user?
        !!@service_user
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

      def require_classic_user!
        if service_user?
          raise Identikey::UsageError, "This command is not supported with Service users"
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
