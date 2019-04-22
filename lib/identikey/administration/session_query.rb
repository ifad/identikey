module Identikey
  class Administration < Base

    class SessionQuery
      def self.all(session_id:)
        client = Identikey::Administration.new

        stat, sessions, error = client.admin_session_query(session_id: session_id)

        if stat != 'STAT_SUCCESS'
          raise Identikey::Error, "query failed: #{stat} - #{error}"
        end

        sessions.map do |session|
          new(
            idx:        session['ADMINSESSIONFLD_SESSION_IDX'],
            username:   session['ADMINSESSIONFLD_LOGIN_NAME'],
            domain:     session['ADMINSESSIONFLD_DOMAIN'],
            location:   session['ADMINSESSIONFLD_LOCATION'],
            start_time: session['ADMINSESSIONFLD_START_TIME']
          )
        end
      end

      attr_reader :idx, :username, :domain, :location, :start_time

      def initialize(idx:, username:, domain:, location:, start_time:)
        @idx        = idx
        @username   = username
        @domain     = domain
        @location   = location
        @start_time = start_time
      end
    end

  end
end
