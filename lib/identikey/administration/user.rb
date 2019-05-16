module Identikey
  class Administration < Base

    class User
      def self.find(session:, username:, domain:)
        new(session).find(username, domain)
      end

      attr_accessor :username
      attr_accessor :email
      attr_accessor :mobile
      attr_accessor :phone
      attr_accessor :created_at
      attr_accessor :updated_at
      attr_accessor :has_digipass
      attr_accessor :domain
      attr_accessor :ou
      attr_accessor :digipass
      attr_accessor :local_auth
      attr_accessor :backend_auth
      attr_accessor :disabled
      attr_accessor :lock_count
      attr_accessor :locked
      attr_accessor :last_auth_success_at
      attr_accessor :expires_at
      attr_accessor :expired
      attr_accessor :last_auth_attempt_at

      def initialize(session, user = nil)
        @session = session

        replace(user) if user
      end

      def find(username, domain)
        stat, user, error = @session.execute(
          :user_execute_VIEW, username: username, domain: domain)

        if stat != 'STAT_SUCCESS'
          raise Identikey::Error, "Find user failed: #{stat} - #{error}"
        end

        replace(user, persisted: true)
      end

      def persisted?
        @persisted || false
      end

      def reload
        find(self.username, self.domain)
      end

      def save!
        method = persisted? ? :user_execute_UPDATE : :user_execute_CREATE

        stat, user, error = @session.execute(method, attributes: {
          USERFLD_BACKEND_AUTH:        self.backend_auth,
          USERFLD_DISABLED:            self.disabled,
          USERFLD_DOMAIN:              self.domain,
          USERFLD_EMAIL:               self.email,
          USERFLD_LOCAL_AUTH:          self.local_auth,
          USERFLD_LOCKED:              self.locked,
          USERFLD_MOBILE:              self.mobile,
          USERFLD_ORGANIZATIONAL_UNIT: self.ou,
          USERFLD_PHONE:               self.phone,
          USERFLD_USERID:              self.username
        })

        if stat != 'STAT_SUCCESS'
          raise Identikey::Error, "Save user failed: #{stat} - #{error}"
        end

        replace(user, persisted: true)
      end

      protected
        def replace(user, persisted: false)
          self.username             = user['USERFLD_USERID']
          self.email                = user['USERFLD_EMAIL']
          self.mobile               = user['USERFLD_MOBILE']
          self.phone                = user['USERFLD_PHONE']
          self.created_at           = user['USERFLD_CREATE_TIME']
          self.updated_at           = user['USERFLD_MODIFY_TIME']
          self.has_digipass         = user['USERFLD_HAS_DP'] == 'Assigned'
          self.domain               = user['USERFLD_DOMAIN']
          self.ou                   = user['USERFLD_ORGANIZATIONAL_UNIT']
          self.digipass             = user['USERFLD_ASSIGNED_DIGIPASS']&.split(',') || [ ]
          self.local_auth           = user['USERFLD_LOCAL_AUTH']
          self.backend_auth         = user['USERFLD_BACKEND_AUTH']
          self.disabled             = user['USERFLD_DISABLED']
          self.lock_count           = user['USERFLD_LOCK_COUNT']
          self.locked               = user['USERFLD_LOCKED']
          self.last_auth_success_at = user['USERFLD_LASTAUTH_TIME']
          self.expires_at           = user['USERFLD_EXPIRATION_TIME']
          self.expired              = user['USERFLD_EXPIRED']
          self.last_auth_attempt_at = user['USERFLD_LASTAUTHREQ_TIME']

          @persisted = persisted

          self
        end
    end

  end
end
