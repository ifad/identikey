module Identikey
  class Administration < Base

    class SessionQuery
      def self.all(session:)
        stat, sessions, error = session.execute(:admin_session_query)

        if stat != 'STAT_SUCCESS'
          raise Identikey::OperationFailed, "query failed: #{stat} - #{error}"
        end

        sessions.map do |sess|
          new(
            idx:        sess['ADMINSESSIONFLD_SESSION_IDX'],
            username:   sess['ADMINSESSIONFLD_LOGIN_NAME'],
            domain:     sess['ADMINSESSIONFLD_DOMAIN'],
            location:   sess['ADMINSESSIONFLD_LOCATION'],
            start_time: sess['ADMINSESSIONFLD_START_TIME']
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
