module Identikey
  class Administration < Base

    class User
      def self.find(session:, username:, domain:)
        new(session).find(username, domain)
      end

      def initialize(session, user = nil)
        @session = session

        replace(user) if user
      end

      def replace(user)
        @attributes = {
          username:              user['USERFLD_USERID'],
          email:                 user['USERFLD_EMAIL'],
          mobile:                user['USERFLD_MOBILE'],
          created_at:            user['USERFLD_CREATE_TIME'],
          updated_at:            user['USERFLD_MODIFY_TIME'],
          has_digipass:          user['USERFLD_HAS_DP'] == 'Assigned',
          domain:                user['USERFLD_DOMAIN'],
          ou:                    user['USERFLD_ORGANIZATIONAL_UNIT'],
          digipass:              user['USERFLD_ASSIGNED_DIGIPASS']&.split(',') || [ ],
          local_auth:            user['USERFLD_LOCAL_AUTH'],
          backend_auth:          user['USERFLD_BACKEND_AUTH'],
          disabled:              user['USERFLD_DISABLED'],
          lock_count:            user['USERFLD_LOCK_COUNT'],
          locked:                user['USERFLD_LOCKED'],
          last_auth_success_at:  user['USERFLD_LASTAUTH_TIME'],
          expires_at:            user['USERFLD_EXPIRATION_TIME'],
          expired:               user['USERFLD_EXPIRED'],
          last_auth_attempt_at:  user['USERFLD_LASTAUTHREQ_TIME']
        }.freeze

        self
      end

      def find(username, domain)
        stat, user, error = @session.execute(
          :user_execute_VIEW, username: username, domain: domain)

        if stat != 'STAT_SUCCESS'
          raise Identikey::Error, "Find user failed: #{stat} - #{error}"
        end

        replace(user)
      end

      def reload
        find(self.username, self.domain)
      end

      def method_missing(name, *args, &block)
        if @attributes.key?(name)
          @attributes.fetch(name)
        else
          super(name, *args, &block)
        end
      end
    end

  end
end
